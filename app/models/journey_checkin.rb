# frozen_string_literal: true

MAX_IMAGE_COUNT_PER_CHECKIN = 4

class JourneyCheckin < ApplicationRecord
  include ReviewSnapshot

  belongs_to :journey
  has_many :images, as: :imageable, dependent: :destroy

  delegate :user_id, to: :journey

  validates :review_id,
            uniqueness: {
              scope: :journey_id,
              message: I18n.t('messages.api.duplicate_checkin')
            }
  validates :images,
            length: {
              maximum: MAX_IMAGE_COUNT_PER_CHECKIN,
              message: I18n.t('messages.api.images_per_checkin_reached_limit')
            }
  validate :journey_must_be_in_progress, on: :create

  private

  def journey_must_be_in_progress
    return if journey.blank?
    return if journey.in_progress?

    errors.add(:base, I18n.t('messages.api.journey_not_in_progress'))
  end
end
