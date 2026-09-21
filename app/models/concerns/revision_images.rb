# frozen_string_literal: true

module RevisionImages
  extend ActiveSupport::Concern

  # attr_readonly covers the columns, but the images are reached through an
  # association Rails leaves writable, so a written revision would still be
  # able to change what it shows.
  module WrittenOnce
    MUTATORS = %i[<< push concat build create create! delete destroy clear delete_all destroy_all].freeze

    MUTATORS.each do |mutator|
      define_method(mutator) do |*args, &block|
        proxy_association.owner.send(:reject_change_after_writing)

        super(*args, &block)
      end
    end
  end

  included do
    validate :images_must_belong_to_author, if: :images_submitted?

    attr_writer :images_submitted
  end

  def images=(records)
    reject_change_after_writing
    super
  end

  def image_ids=(ids)
    reject_change_after_writing
    super
  end

  private

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
