class Image < ApplicationRecord
  belongs_to :review

  validates :review_id,
            presence: true
  validates :url,
            presence: true,
            uniqueness: true,
            format: {
              allow_blank: false,
              with: /\A#{URI::DEFAULT_PARSER.make_regexp(%w[http https])}\z/,
              scrict: Exceptions::InvalidUri
            }

  validate :validate_image_count

  before_destroy :delete_object

  MAX_IMAGE_COUNT_PER_REVIEW = 4

  STORAGE_SCOPES = [
    'https://www.googleapis.com/auth/cloud-platform',
    'https://www.googleapis.com/auth/devstorage.read_write'
  ].freeze

  def file_name
    File.basename(CGI.unescape(url))
  end

  def file_name_was
    return '' if url_was.blank?

    File.basename(CGI.unescape(url_was))
  end

  def thumbnail_url(size = '200x200')
    ext = File.extname(url)
    "#{ENV['CLOUD_STORAGE_ENDPOINT']}/#{ENV['CLOUD_STORAGE_BUCKET_NAME']}/images/thumbnails/#{File.basename(file_name,
                                                                                                            ext)}_#{size}#{ext}"
  end

  private

  def validate_image_count
    return unless review.images.size >= MAX_IMAGE_COUNT_PER_REVIEW

    raise Exceptions::BadRequest, 'Images per report reached limit'
  end

  def delete_object
    file = bucket.file("images/#{file_name}")

    if file.blank?
      Rails.logger.warn("Object #{file_name} not found")
      return
    end

    file.delete
  end

  def storage
    @storage ||= Google::Cloud::Storage.new(
      credentials: Google::Auth::ServiceAccountCredentials.make_creds(
        scope: STORAGE_SCOPES
      )
    )
  end

  def bucket
    @bucket ||= storage.bucket(ENV['CLOUD_STORAGE_BUCKET_NAME'])
  end
end
