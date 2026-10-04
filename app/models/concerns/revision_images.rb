# frozen_string_literal: true

module RevisionImages
  extend ActiveSupport::Concern

  included do
    validate :images_must_belong_to_author, if: :images_submitted?

    attr_writer :images_submitted
  end

  private

  def images_submitted?
    @images_submitted.present?
  end

  def images_must_belong_to_author
    return if images.all? { |image| image.user_id == user_id }

    errors.add(:images, :invalid)
  end
end
