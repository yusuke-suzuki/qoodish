require 'google/cloud/storage'

class Review < ApplicationRecord
  belongs_to :user
  belongs_to :map
  has_many :notifications, as: :notifiable
  has_many :comments, as: :commentable
  has_many :votes, as: :votable, dependent: :destroy

  before_validation :remove_carriage_return

  validates :comment,
            presence: {
              strict: Exceptions::CommentNotSpecified
            },
            length: {
              allow_blank: false,
              maximum: 500,
              strict: Exceptions::CommentExceeded
            }
  validates :user_id,
            presence: true
  validates :place_id_val,
            presence: {
              strict: Exceptions::PlaceIdNotSpecified
            },
            uniqueness: {
              scope: %i[map_id user_id],
              strict: Exceptions::DuplicateReview
            }
  validates :map_id,
            presence: {
              strict: Exceptions::MapNotSpecified
            }
  validates :image_url,
            format: {
              allow_blank: true,
              with: /\A#{URI.regexp(%w[http https])}\z/,
              scrict: Exceptions::InvalidUri
            }
  validate :validate_spot

  FEED_PER_PAGE = 12

  scope :public_open, lambda {
    joins(:map)
      .where(maps: { private: false })
  }

  scope :referenceable_by, lambda { |current_user|
    following_by(current_user)
      .or(public_open)
  }

  scope :following_by, lambda { |user|
    joins(:map).where(maps: { id: user.following_maps })
  }

  scope :latest_feed, lambda {
    order(created_at: :desc)
      .limit(FEED_PER_PAGE)
  }

  scope :feed_before, lambda { |created_at|
    where('reviews.created_at < ?', Time.parse(created_at))
      .order(created_at: :desc)
      .limit(FEED_PER_PAGE)
  }

  scope :popular, lambda {
    joins(:votes)
      .group('reviews.id')
      .order('count(votes.id) desc')
      .limit(10)
  }

  before_update :update_image, if: :will_save_change_to_image_url?
  before_destroy :delete_image, if: :image_url

  def spot
    @spot ||= Spot.new(place_id_val, self)
  end

  def name
    spot.name
  end

  def image_name
    return '' if image_url.blank?

    File.basename(CGI.unescape(image_url))
  end

  def image_name_was
    return '' if image_url_was.blank?

    File.basename(CGI.unescape(image_url_was))
  end

  def thumbnail_url(size = '200x200')
    return '' if image_url.blank?

    ext = File.extname(image_url)
    "#{ENV['CLOUD_STORAGE_ENDPOINT']}/#{ENV['CLOUD_STORAGE_BUCKET_NAME']}/images/thumbnails/#{File.basename(image_name, ext)}_#{size}#{ext}"
  end

  private

  def remove_carriage_return
    return unless comment

    comment.delete!("\r")
  end

  def validate_spot
    raise Exceptions::PlaceNotFound if spot.name.blank?
  end

  def update_image
    if image_url_was.present?
      delete_object(image_name_was)
    end
  end

  def delete_image
    return if image_url.blank?

    delete_object(image_name)
  end

  def delete_object(file_name)
    return if file_name.blank?

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
