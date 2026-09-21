# frozen_string_literal: true

module RevisableImages
  extend ActiveSupport::Concern

  include Revisable

  included do
    attr_accessor :submitted_image_ids
  end

  def revise!(user:, image_ids: nil, **content)
    self.submitted_image_ids = image_ids

    super(user: user, **content)
  end

  private

  def revised_anything?
    super || submitted_images_differ?
  end

  def submitted_images_differ?
    return false if submitted_image_ids.nil?

    submitted_image_ids.map(&:to_i).sort != carried_image_ids.sort
  end

  def revision_content
    super.merge(
      images_submitted: !submitted_image_ids.nil?,
      image_ids: submitted_image_ids || carried_image_ids
    )
  end

  def forget_submission
    super

    self.submitted_image_ids = nil
  end

  def carried_image_ids
    current_revision&.image_ids || []
  end
end
