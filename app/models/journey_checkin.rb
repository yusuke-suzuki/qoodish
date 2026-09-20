# frozen_string_literal: true

MAX_CHECKIN_NOTE_LENGTH = 500

class JourneyCheckin < ApplicationRecord
  include PinSnapshot
  include Revisable

  self.revision_attributes = %i[note checked_in_at]

  belongs_to :journey
  belongs_to :current_revision, class_name: 'JourneyCheckinRevision', optional: true
  has_many :revisions,
           -> { order(:id) },
           class_name: 'JourneyCheckinRevision',
           dependent: :destroy,
           inverse_of: :journey_checkin
  has_many :images, through: :current_revision

  enum :status, { recorded: 'recorded', deleted: 'deleted' }, validate: true

  delegate :user_id, to: :journey

  normalizes :note, with: ->(text) { text.delete("\r") }

  before_validation :set_default_checked_in_at, on: :create

  validates :pin_id,
            uniqueness: {
              scope: :journey_id,
              conditions: -> { not_deleted },
              message: I18n.t('messages.api.duplicate_checkin')
            }
  validates :note,
            length: {
              maximum: MAX_CHECKIN_NOTE_LENGTH,
              message: I18n.t('messages.api.checkin_note_exceeded')
            }
  validate :checked_in_at_must_be_within_journey_period, if: :checked_in_at_changed?

  def self.authored_by(_user) = {}

  private

  def set_default_checked_in_at
    self.checked_in_at ||= Time.current
  end

  def checked_in_at_must_be_within_journey_period
    return if journey.blank?

    unless journey.started?
      errors.add(:base, I18n.t('messages.api.journey_not_started'))
      return
    end

    upper_bound = journey.finished_at || Time.current
    return if checked_in_at.present? && checked_in_at.between?(journey.started_at, upper_bound)

    errors.add(:checked_in_at, I18n.t('messages.api.checkin_time_outside_journey_period'))
  end
end
