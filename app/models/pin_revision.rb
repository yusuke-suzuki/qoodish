# frozen_string_literal: true

MAX_IMAGE_COUNT_PER_PIN = 4

class PinRevision < ApplicationRecord
  belongs_to :pin
  belongs_to :user
  has_many :pin_revision_images, dependent: :destroy
  has_many :images, -> { order(:id) }, through: :pin_revision_images

  attr_readonly :pin_id, :user_id, :name, :comment, :latitude, :longitude, :status

  enum :status, { published: 0, deleted: 1 }

  validates :name,
            presence: true
  validates :comment,
            presence: true
  validates :latitude,
            presence: true
  validates :longitude,
            presence: true
  validates :images, length: {
    maximum: MAX_IMAGE_COUNT_PER_PIN,
    message: I18n.t('messages.api.images_per_report_reached_limit')
  }
  validate :images_must_belong_to_author

  # attr_readonly covers the columns, but the images are reached through an
  # association Rails leaves writable, so a written revision would still be
  # able to change what it shows.
  def images=(records)
    reject_change_after_writing
    super
  end

  def image_ids=(ids)
    reject_change_after_writing
    super
  end

  private

  def reject_change_after_writing
    return unless persisted?

    raise ActiveRecord::ReadOnlyRecord, 'a revision keeps the images it was written with'
  end

  def images_must_belong_to_author
    return if images.all? { |image| image.user_id == user_id }

    errors.add(:images, :invalid)
  end
end
