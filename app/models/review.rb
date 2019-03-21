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
              maximum: 200,
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

  FEED_PER_PAGE = 10

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

  def spot
    @spot ||= Spot.new(place_id_val, thumbnail_url)
  end

  def name
    spot.name
  end

  def image_name
    return '' if image_url.blank?

    File.basename(CGI.unescape(image_url))
  end

  def thumbnail_url
    return '' if image_url.blank?

    "#{ENV['CLOUD_STORAGE_ENDPOINT']}/#{ENV['CLOUD_STORAGE_BUCKET_NAME']}/images/thumb_#{image_name}"
  end

  private

  def remove_carriage_return
    return unless comment

    comment.delete!("\r")
  end

  def validate_spot
    raise Exceptions::PlaceNotFound if spot.name.blank?
  end
end
