class Image < ApplicationRecord
  belongs_to :review

  validates :review_id,
            presence: true
  validates :url,
            presence: true,
            uniqueness: true,
            format: {
              allow_blank: false,
              with: /\A#{URI.regexp(%w[http https])}\z/,
              scrict: Exceptions::InvalidUri
            }

  validate :validate_image_count

  before_destroy :delete_object

  MAX_IMAGE_COUNT_PER_REVIEW = 4

  def file_name
    File.basename(CGI.unescape(url))
  end

  def file_name_was
    return '' if url_was.blank?

    File.basename(CGI.unescape(url_was))
  end

  def thumbnail_url(size = '200x200')
    ext = File.extname(url)
    "#{ENV['CLOUD_STORAGE_ENDPOINT']}/#{ENV['CLOUD_STORAGE_BUCKET_NAME']}/images/thumbnails/#{File.basename(file_name, ext)}_#{size}#{ext}"
  end

  private

  def validate_image_count
    if MAX_IMAGE_COUNT_PER_REVIEW <= review.images.size
      raise Exceptions::BadRequest.new('Images per report reached limit')
    end
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
      project_id: ENV['GCP_PROJECT_ID'],
      credentials: ENV['GCP_CREDENTIALS']
    )
  end

  def bucket
    @bucket ||= storage.bucket(ENV['CLOUD_STORAGE_BUCKET_NAME'])
  end
end
