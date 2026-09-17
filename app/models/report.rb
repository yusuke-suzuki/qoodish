MAX_REPORT_DETAILS_LENGTH = 2000
MAX_REPORT_EVIDENCE_URL_LENGTH = 2000

class Report < ApplicationRecord
  MODERATABLE_TYPES = [Pin.name, Comment.name, Map.name, Chapter.name, Journal.name, User.name].freeze
  DETAILS_REQUIRED_CATEGORIES = %w[copyright privacy other].freeze

  belongs_to :moderatable, polymorphic: true, optional: true
  belongs_to :reporter, class_name: User.name, optional: true

  enum :category, {
    spam: 'spam',
    harassment: 'harassment',
    hate: 'hate',
    sexual: 'sexual',
    violence: 'violence',
    illegal: 'illegal',
    privacy: 'privacy',
    copyright: 'copyright',
    impersonation: 'impersonation',
    other: 'other'
  }, validate: true

  normalizes :details, with: ->(text) { text.delete("\r") }
  normalizes :reporter_email, with: ->(email) { email.strip.downcase }

  validates :moderatable, presence: true, on: :create
  validates :moderatable_type, inclusion: { in: MODERATABLE_TYPES }
  validates :locale, inclusion: { in: -> (_report) { I18n.available_locales.map(&:to_s) } }
  validates :details,
            presence: { message: ->(_report, _data) { I18n.t('messages.api.report_details_required') } },
            if: :details_required?
  validates :details,
            length: {
              allow_blank: true,
              maximum: MAX_REPORT_DETAILS_LENGTH,
              message: ->(_report, _data) { I18n.t('messages.api.report_details_exceed') }
            }
  validates :evidence_url,
            format: {
              with: URI::DEFAULT_PARSER.make_regexp(%w[http https]),
              allow_blank: true,
              message: ->(_report, _data) { I18n.t('messages.api.invalid_uri') }
            },
            length: { allow_blank: true, maximum: MAX_REPORT_EVIDENCE_URL_LENGTH }
  validates :reporter_email,
            presence: { message: ->(_report, _data) { I18n.t('messages.api.report_email_required') } },
            if: :reporter_email_required?
  validates :reporter_email,
            format: {
              with: URI::MailTo::EMAIL_REGEXP,
              allow_blank: true,
              message: ->(_report, _data) { I18n.t('messages.api.report_email_invalid') }
            }
  validates :reporter_id,
            uniqueness: {
              scope: %i[moderatable_type moderatable_id],
              allow_nil: true,
              message: ->(_report, _data) { I18n.t('messages.api.duplicate_report') }
            }
  validates :reporter_email,
            uniqueness: {
              scope: %i[moderatable_type moderatable_id],
              allow_blank: true,
              message: ->(_report, _data) { I18n.t('messages.api.duplicate_report') }
            }
  validate :reporter_is_not_the_author, on: :create

  before_validation :assign_locale, on: :create
  before_create :take_content_snapshot
  before_create :note_reported_revision
  after_create_commit :deliver_receipt_mails

  scope :pending, lambda {
    where.not(
      ModerationDecision
        .where('moderation_decisions.moderatable_type = reports.moderatable_type')
        .where('moderation_decisions.moderatable_id = reports.moderatable_id')
        .where('moderation_decisions.created_at >= reports.created_at')
        .arel.exists
    )
  }

  def self.file!(attributes)
    create!(attributes)
  rescue ActiveRecord::RecordNotUnique
    raise Exceptions::UnprocessableContent, I18n.t('messages.api.duplicate_report')
  end

  def self.moderatable_for(type, id, viewer)
    unless MODERATABLE_TYPES.include?(type)
      raise Exceptions::BadRequest, I18n.t('messages.api.report_type_not_supported')
    end

    moderatable_scope(type, viewer).find_by!(id: id)
  end

  def self.moderatable_scope(type, viewer)
    case type
    when Pin.name
      Pin.referenceable_by(viewer)
    when Comment.name
      Comment.not_deleted.visible.where(commentable_type: Pin.name,
                                        commentable_id: moderatable_scope(Pin.name, viewer).select(:id))
    when Map.name
      Map.referenceable_by(viewer)
    when Chapter.name
      Chapter.referenceable_by(viewer)
    when Journal.name
      Journal.all
    when User.name
      User.all
    end
  end

  def self.operator_email
    ENV['REPORT_NOTIFICATION_EMAIL']
  end

  def readonly?
    persisted?
  end

  def decision
    ModerationDecision
      .where(moderatable_type: moderatable_type, moderatable_id: moderatable_id)
      .where('moderation_decisions.created_at >= ?', created_at)
      .order(:created_at, :id)
      .first
  end

  def status
    decision&.outcome || 'pending'
  end

  def reporter_address
    reporter&.email.presence || reporter_email.presence
  end

  def author
    return nil if moderatable.blank?

    moderatable.is_a?(User) ? moderatable : moderatable.user
  end

  def edited_since_filed?
    return false if moderatable.blank? || reported_revision_id.blank?

    moderatable.current_revision_id != reported_revision_id
  end

  def reviewed_as_filed?(decision)
    reported_revision_id.present? && decision.reviewed_revision_id == reported_revision_id
  end

  private

  def details_required?
    DETAILS_REQUIRED_CATEGORIES.include?(category)
  end

  def reporter_email_required?
    reporter.nil?
  end

  def reporter_is_not_the_author
    return if reporter.blank? || author.blank?
    return unless author.id == reporter.id

    errors.add(:moderatable, I18n.t('messages.api.report_own_content'))
  end

  def assign_locale
    self.locale ||= RequestContext.locale.presence || I18n.locale
  end

  def take_content_snapshot
    self.content_snapshot = ContentSnapshot.new(moderatable).text
  end

  def note_reported_revision
    self.reported_revision_id = moderatable&.current_revision_id
  end

  def deliver_receipt_mails
    ModerationMailer.report_received(self).deliver_later if self.class.operator_email.present?
    ModerationMailer.report_acknowledged(self).deliver_later if reporter_address.present?
  end
end
