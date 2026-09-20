# frozen_string_literal: true

MAX_IMAGE_COUNT_PER_CHECKIN = 4

class JourneyCheckinRevision < ApplicationRecord
  include Revision

  belongs_to :journey_checkin
  belongs_to :user
  has_many :journey_checkin_revision_images, dependent: :destroy
  has_many :images, -> { order(:id) }, through: :journey_checkin_revision_images

  alias_method :revisable, :journey_checkin

  enum :status, { recorded: 'recorded', deleted: 'deleted' }, validate: true

  attr_readonly :journey_checkin_id, :user_id, :note, :checked_in_at, :status

  validates :checked_in_at,
            presence: true
  # The limit judges what a caller may submit, not what a revision may record.
  # A checkin backfilled from the legacy imageable column can already hold more
  # images than it allows, and its history has to stay recordable and its later
  # revisions possible.
  validates :images,
            length: {
              maximum: MAX_IMAGE_COUNT_PER_CHECKIN,
              message: I18n.t('messages.api.images_per_checkin_reached_limit')
            },
            if: :images_submitted?
end
