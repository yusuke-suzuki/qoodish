# frozen_string_literal: true

MAX_IMAGE_COUNT_PER_PIN = 4

class PinRevision < ApplicationRecord
  include Revision

  belongs_to :pin
  belongs_to :user
  has_many :pin_revision_images, dependent: :destroy
  has_many :images, -> { order(:id) }, through: :pin_revision_images

  alias_method :revisable, :pin

  attr_readonly :pin_id, :user_id, :name, :comment, :latitude, :longitude, :status

  validates :name,
            presence: true
  validates :comment,
            presence: true
  validates :latitude,
            presence: true
  validates :longitude,
            presence: true
  # The limit judges what a caller may submit, not what a revision may record.
  # A pin backfilled from the legacy imageable column can already hold more
  # images than it allows, and its history has to stay recordable and its later
  # revisions possible.
  validates :images,
            length: {
              maximum: MAX_IMAGE_COUNT_PER_PIN,
              message: I18n.t('messages.api.images_per_report_reached_limit')
            },
            if: :images_submitted?
end
