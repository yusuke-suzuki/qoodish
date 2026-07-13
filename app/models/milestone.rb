# frozen_string_literal: true

class Milestone < ApplicationRecord
  include ReviewSnapshot

  belongs_to :journey

  before_validation :assign_position, on: :create

  validates :review_id,
            uniqueness: {
              scope: :journey_id,
              message: I18n.t('messages.api.duplicate_milestone')
            }
  validates :position,
            presence: true
  validate :journey_must_be_unfinished, on: :create

  private

  def assign_position
    return if journey.blank? || position.present?

    self.position = (journey.milestones.maximum(:position) || 0) + 1
  end

  def journey_must_be_unfinished
    return if journey.blank?
    return unless journey.finished?

    errors.add(:base, I18n.t('messages.api.journey_already_finished'))
  end
end
