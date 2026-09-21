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

    submitted_image_ids.map(&:to_i).sort != (current_revision&.image_ids || []).sort
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

  # An edit that lands before the backfill reaches this record would otherwise
  # write an empty revision and take the record out of the backfill's reach,
  # losing the images the legacy column still holds.
  def carried_image_ids
    return current_revision.image_ids if current_revision

    Image.where(imageable: self).order(:id).ids
  end
end
