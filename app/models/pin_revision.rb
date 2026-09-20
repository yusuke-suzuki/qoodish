# frozen_string_literal: true

MAX_IMAGE_COUNT_PER_PIN = 4

class PinRevision < ApplicationRecord
  belongs_to :pin
  belongs_to :user
  has_many :pin_revision_images, dependent: :destroy
  has_many :images, -> { order(:id) }, through: :pin_revision_images

  attr_readonly :pin_id, :user_id, :name, :comment, :latitude, :longitude, :status

  enum :status, { published: 'published', deleted: 'deleted' }, validate: true

  after_create :become_current

  validates :name,
            presence: true
  validates :comment,
            presence: true
  validates :latitude,
            presence: true
  validates :longitude,
            presence: true
  # Both of these judge what a caller may submit, not what a revision may
  # record. A pin backfilled from the legacy imageable column can already hold
  # more images than the limit allows, or images someone else uploaded, and its
  # history has to stay recordable and its later revisions possible.
  validates :images,
            length: {
              maximum: MAX_IMAGE_COUNT_PER_PIN,
              message: I18n.t('messages.api.images_per_report_reached_limit')
            },
            if: :images_submitted?
  validate :images_must_belong_to_author, if: :images_submitted?

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

  attr_writer :images_submitted

  private

  def become_current
    pin.current_revision = self
    pin.update_column(:current_revision_id, id)
  end

  def images_submitted?
    @images_submitted.present?
  end

  def reject_change_after_writing
    return unless persisted?

    raise ActiveRecord::ReadOnlyRecord, 'a revision keeps the images it was written with'
  end

  def images_must_belong_to_author
    return if images.all? { |image| image.user_id == user_id }

    errors.add(:images, :invalid)
  end
end
