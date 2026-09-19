class ModerationDecision < ApplicationRecord
  UNREMOVABLE_TYPES = [User.name, Journal.name].freeze
  GONE_MESSAGE = 'the content is gone; close the report as unavailable instead'.freeze
  UNREMOVABLE_MESSAGE = 'an account or a journal is not removed through moderation; keep the report instead'.freeze
  STILL_THERE_MESSAGE = 'the content is still there; keep or remove it instead of closing the report'.freeze

  belongs_to :moderatable, polymorphic: true, optional: true
  belongs_to :author, class_name: User.name, optional: true
  belongs_to :moderator, class_name: User.name, optional: true

  enum :outcome, { kept: 'kept', removed: 'removed', unavailable: 'unavailable' }, validate: true

  normalizes :reason, with: ->(text) { text.delete("\r") }

  validates :moderatable, presence: true, on: :create, unless: :unavailable?
  validates :moderatable_type, inclusion: { in: Report::MODERATABLE_TYPES }
  validates :reason, presence: true

  after_create_commit :deliver_decision_mails

  # Ranking once over the decisions of a type and filtering the winners keeps
  # this uncorrelated, so MySQL materialises it once instead of re-running it
  # for every row of the table being filtered.
  def self.removed_ids(type)
    ranked = where(moderatable_type: type)
             .select(
               :moderatable_id,
               :outcome,
               'ROW_NUMBER() OVER (PARTITION BY moderatable_id ORDER BY created_at DESC, id DESC) AS ordinal'
             )

    unscoped
      .select('latest_decisions.moderatable_id')
      .from(ranked, :latest_decisions)
      .where(latest_decisions: { ordinal: 1, outcome: 'removed' })
  end

  def self.keep!(moderatable:, reason:, moderator: nil)
    raise ArgumentError, GONE_MESSAGE if moderatable.blank?

    create!(**decision_attributes(moderatable), outcome: 'kept', reason: reason, moderator: moderator)
  end

  def self.remove!(moderatable:, reason:, moderator: nil)
    raise ArgumentError, GONE_MESSAGE if moderatable.blank?

    raise ArgumentError, UNREMOVABLE_MESSAGE if UNREMOVABLE_TYPES.include?(moderatable.class.name)

    create!(**decision_attributes(moderatable), outcome: 'removed', reason: reason, moderator: moderator)
  end

  def self.close_unavailable!(report:, reason:, moderator: nil)
    raise ArgumentError, STILL_THERE_MESSAGE if report.moderatable.present?

    create!(
      moderatable_type: report.moderatable_type,
      moderatable_id: report.moderatable_id,
      content_snapshot: report.content_snapshot,
      outcome: 'unavailable',
      reason: reason,
      moderator: moderator
    )
  end

  def self.decision_attributes(moderatable)
    {
      moderatable: moderatable,
      author: moderatable.is_a?(User) ? moderatable : moderatable.user,
      content_snapshot: ContentSnapshot.new(moderatable).text
    }
  end
  private_class_method :decision_attributes

  def readonly?
    persisted?
  end

  def previous
    self.class
        .where(moderatable_type: moderatable_type, moderatable_id: moderatable_id)
        .where('(moderation_decisions.created_at, moderation_decisions.id) < (?, ?)', created_at, id)
        .order(:created_at, :id)
        .last
  end

  def answered_reports
    reports = Report
              .where(moderatable_type: moderatable_type, moderatable_id: moderatable_id)
              .where('reports.created_at <= ?', created_at)
    earlier = previous

    earlier ? reports.where('reports.created_at >= ?', earlier.created_at) : reports
  end

  private

  def deliver_decision_mails
    answered_reports.each do |report|
      ModerationMailer.decision_notified(report, self).deliver_later if report.reporter_address.present?
    end

    ModerationMailer.content_removed(self).deliver_later if removed? && author&.email.present?
  end
end
