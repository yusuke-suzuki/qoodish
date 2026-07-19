# frozen_string_literal: true

MAX_IMAGE_COUNT_PER_CHECKIN = 4
MAX_CHECKIN_NOTE_LENGTH = 500

class JourneyCheckin < ApplicationRecord
  include ReviewSnapshot

  belongs_to :journey
  has_many :images, as: :imageable, dependent: :destroy

  delegate :user_id, to: :journey

  before_validation :remove_carriage_return
  before_validation :set_default_checked_in_at, on: :create

  validates :review_id,
            uniqueness: {
              scope: :journey_id,
              message: I18n.t('messages.api.duplicate_checkin')
            }
  validates :note,
            length: {
              maximum: MAX_CHECKIN_NOTE_LENGTH,
              message: I18n.t('messages.api.checkin_note_exceeded')
            }
  validates :images,
            length: {
              maximum: MAX_IMAGE_COUNT_PER_CHECKIN,
              message: I18n.t('messages.api.images_per_checkin_reached_limit')
            }
  validate :checked_in_at_must_be_within_journey_period, if: :checked_in_at_changed?

  # Nil means the row predates the checked_in_at column, where creation time
  # and visit time were the same thing.
  def checked_in_at
    super || created_at
  end

  private

  def remove_carriage_return
    note.delete!("\r") if note.present?
  end

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
