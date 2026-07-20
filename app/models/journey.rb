# frozen_string_literal: true

MAX_ENCODED_PATH_LENGTH = 1_000_000

class Journey < ApplicationRecord
  belongs_to :user
  belongs_to :map, optional: true
  has_many :milestones, -> { order(:position) }, dependent: :destroy, inverse_of: :journey
  has_many :checkins,
           -> { order(:checked_in_at, :id) },
           class_name: 'JourneyCheckin',
           dependent: :destroy,
           inverse_of: :journey
  has_one :chapter, dependent: :nullify

  validates :user_id,
            presence: true
  validates :map,
            presence: true,
            on: :create
  validates :encoded_path,
            length: {
              maximum: MAX_ENCODED_PATH_LENGTH,
              message: I18n.t('messages.api.journey_encoded_path_exceed')
            }
  validates :map_id,
            uniqueness: {
              scope: :user_id,
              conditions: -> { unfinished },
              message: I18n.t('messages.api.duplicate_unfinished_journey')
            },
            on: :create
  validate :encoded_path_only_while_in_progress, if: :encoded_path_changed?

  scope :unfinished, lambda {
    where(finished_at: nil)
  }

  def started?
    started_at.present?
  end

  def finished?
    finished_at.present?
  end

  def in_progress?
    started? && !finished?
  end

  def start!
    raise Exceptions::Conflict, I18n.t('messages.api.journey_already_started') if started?

    update!(started_at: Time.current)
  end

  def finish!(encoded_path: nil)
    raise Exceptions::Conflict, I18n.t('messages.api.journey_not_started') unless started?
    raise Exceptions::Conflict, I18n.t('messages.api.journey_already_finished') if finished?

    attributes = { finished_at: Time.current }
    attributes[:encoded_path] = encoded_path if encoded_path.present?
    update!(attributes)
  end

  private

  # The trail is submitted together with the finish stamp, so this checks the
  # persisted state (finished_at_was) rather than in_progress?, which would
  # already read the finished_at being set in the same save.
  def encoded_path_only_while_in_progress
    return if encoded_path.blank?
    return if started? && finished_at_was.nil?

    errors.add(:encoded_path, I18n.t('messages.api.journey_not_in_progress'))
  end
end
