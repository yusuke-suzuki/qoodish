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

  validates :moderatable, presence: true, on: :create
  validates :reporter, presence: true, on: :create
  validates :reporter, comparison: { other_than: :author }, allow_nil: true, on: :create
  validates :moderatable_id,
            uniqueness: { scope: %i[moderatable_type reporter_id], conditions: -> { pending } },
            if: :reporter_id?, on: :create
  validates :moderatable_type, inclusion: { in: MODERATABLE_TYPES }
  validates :locale, inclusion: { in: -> (_report) { I18n.available_locales.map(&:to_s) } }
  validates :details, presence: true, if: :details_required?
  validates :details, length: { allow_blank: true, maximum: MAX_REPORT_DETAILS_LENGTH }
  validates :evidence_url,
            format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), allow_blank: true },
            length: { allow_blank: true, maximum: MAX_REPORT_EVIDENCE_URL_LENGTH }

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
    attributes[:reporter].with_lock { create!(attributes) }
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

  def decisions
    ModerationDecision
      .where(moderatable_type: moderatable_type, moderatable_id: moderatable_id)
      .order(:created_at, :id)
  end

  def decision
    decisions.where('moderation_decisions.created_at >= ?', created_at).first
  end

  def other_pending_reports
    Report
      .pending
      .where(moderatable_type: moderatable_type, moderatable_id: moderatable_id)
      .where.not(id: id)
      .order(:created_at, :id)
  end

  def decide!(staff_member:, **decision)
    ModerationDecision.record!(report: self, staff_member: staff_member, **decision)
  end

  def moderatable_parent
    case moderatable
    when Comment then moderatable.commentable
    when Journal then moderatable.user
    end
  end

  def status
    decision&.outcome || 'pending'
  end

  def reporter_address
    reporter&.email.presence
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
