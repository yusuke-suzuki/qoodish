class ModerationDecision < ApplicationRecord
  UNREMOVABLE_TYPES = [User.name, Journal.name].freeze

  belongs_to :moderatable, polymorphic: true, optional: true
  belongs_to :author, class_name: User.name, optional: true
  belongs_to :moderator, class_name: User.name, optional: true
  belongs_to :staff_member, class_name: Admin::StaffMember.name, optional: true

  enum :outcome, { kept: 'kept', removed: 'removed', unavailable: 'unavailable' }, validate: true

  normalizes :reason, with: ->(text) { text.delete("\r") }

  validates :moderatable_type, inclusion: { in: Report::MODERATABLE_TYPES }
  validates :reason, presence: true
  validates :staff_member, presence: true, on: :create
  validates :moderatable, presence: true, on: :create, unless: :unavailable?
  validates :moderatable, absence: true, on: :create, if: :unavailable?
  validates :moderatable_type, exclusion: { in: UNREMOVABLE_TYPES }, on: :create, if: :removed?

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

  def self.record!(report:, staff_member:, **decision)
    target = report.moderatable
    attributes = target && decision[:outcome] != 'unavailable' ? decision_attributes(target) : report_attributes(report)

    create!(**attributes, staff_member: staff_member, **decision)
  end

  def self.decision_attributes(moderatable)
    {
      moderatable: moderatable,
      author: moderatable.is_a?(User) ? moderatable : moderatable.user,
      content_snapshot: ContentSnapshot.new(moderatable).text,
      reviewed_revision_id: moderatable.current_revision_id
    }
  end
  private_class_method :decision_attributes

  def self.report_attributes(report)
    {
      moderatable_type: report.moderatable_type,
      moderatable_id: report.moderatable_id,
      content_snapshot: report.content_snapshot,
      reviewed_revision_id: report.reported_revision_id
    }
  end
  private_class_method :report_attributes

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
