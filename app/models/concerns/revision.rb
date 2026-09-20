# frozen_string_literal: true

module Revision
  extend ActiveSupport::Concern

  included do
    belongs_to :user

    enum :status, { published: 'published', deleted: 'deleted' }, validate: true

    after_create :become_current

    validate :images_must_belong_to_author, if: :images_submitted?

    attr_writer :images_submitted
  end

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

  def become_current
    revisable.current_revision = self
    revisable.update_column(:current_revision_id, id)
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
