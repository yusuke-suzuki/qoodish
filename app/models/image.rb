class Image < ApplicationRecord
  self.ignored_columns = %w[review_id]

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

  def thumbnail_url(size = '200x200')
    return '' if url.blank?
    return Cloudflare::Images.variant_url_for_legacy_size(url, size) if url.include?(Cloudflare::Images::DELIVERY_HOST)

    ext = File.extname(url)
    "#{ENV['CLOUD_STORAGE_ENDPOINT']}/#{ENV['CLOUD_STORAGE_BUCKET_NAME']}/images/thumbnails/" \
      "#{File.basename(file_name, ext)}_#{size}#{ext}"
  end

  def variants
    if url.include?(Cloudflare::Images::DELIVERY_HOST)
      Cloudflare::Images::NAMED_VARIANTS
        .index_with { |variant| Cloudflare::Images.variant_url(url, variant) }
        .merge(url: url)
    else
      # GCS transition fallback: map to pre-generated thumbnails where
      # available, otherwise use the original URL.
      {
        url: url,
        avatar: thumbnail_url('200x200'),
        card: thumbnail_url('400x400'),
        hero: thumbnail_url('800x800'),
        ogp: url
      }
    end
  end

  private

  def uploader_matches_imageable_owner
    expected_user_id = imageable.is_a?(User) ? imageable.id : imageable.user_id
    errors.add(:user, :invalid) unless user_id == expected_user_id
  end

  def file_name
    File.basename(CGI.unescape(url))
  end

  def delete_cloudflare_image
    image_id = Cloudflare::Images.extract_id(url)
    return if image_id.blank?

    Cloudflare::Images.new.delete(image_id)
  rescue Exceptions::InternalServerError, Faraday::Error => e
    Rails.logger.warn("Cloudflare delete failed for image #{id}: #{e.message}")
  end
end
