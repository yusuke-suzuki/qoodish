# frozen_string_literal: true

class JourneyCheckin < ApplicationRecord
  include ReviewSnapshot

  belongs_to :journey

  validates :review_id,
            uniqueness: {
              scope: :journey_id,
              message: I18n.t('messages.api.duplicate_checkin')
            }
  validate :journey_must_be_in_progress, on: :create

  private

  def journey_must_be_in_progress
    return if journey.blank?
    return if journey.in_progress?

    errors.add(:base, I18n.t('messages.api.journey_not_in_progress'))
  end
end
