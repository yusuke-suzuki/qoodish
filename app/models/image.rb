class Image < ApplicationRecord
  # Tolerate the dropped legacy review_id column during the rollout window: an
  # API instance that booted before the drop migration cached it and would
  # otherwise emit it in INSERTs. Remove once all instances run the new schema.
  self.ignored_columns += %w[review_id]

  belongs_to :user
  belongs_to :imageable, polymorphic: true, optional: true

  validates :url,
            presence: true,
            uniqueness: true,
            format: {
              allow_blank: false,
              with: /\A#{URI::DEFAULT_PARSER.make_regexp(%w[http https])}\z/,
              message: I18n.t('messages.api.invalid_uri')
            }
  validate :uploader_matches_imageable_owner,
           if: -> { imageable && (imageable_id_changed? || imageable_type_changed?) }

  before_destroy :delete_cloudflare_image

  def variants
    Cloudflare::Images::NAMED_VARIANTS
      .index_with { |variant| Cloudflare::Images.variant_url(url, variant) }
      .merge(url: url)
  end

  private

  def uploader_matches_imageable_owner
    expected_user_id = imageable.is_a?(User) ? imageable.id : imageable.user_id
    errors.add(:user, :invalid) unless user_id == expected_user_id
  end

  def delete_cloudflare_image
    image_id = Cloudflare::Images.extract_id(url)
    return if image_id.blank?

    Cloudflare::Images.new.delete(image_id)
  rescue Exceptions::InternalServerError, Faraday::Error => e
    Rails.logger.warn("Cloudflare delete failed for image #{id}: #{e.message}")
  end
end
