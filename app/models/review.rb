# == Schema Information
#
# Table name: reviews
#
#  id           :integer          not null, primary key
#  user_id      :integer          not null
#  map_id       :integer          not null
#  place_id_val :string(255)      not null
#  comment      :string(255)      not null
#  image_url    :string(255)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_reviews_on_map_id                               (map_id)
#  index_reviews_on_place_id_val                         (place_id_val)
#  index_reviews_on_place_id_val_and_map_id_and_user_id  (place_id_val,map_id,user_id) UNIQUE
#  index_reviews_on_user_id                              (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (map_id => maps.id)
#  fk_rails_...  (user_id => users.id)
#

class Review < ApplicationRecord
  belongs_to :user
  belongs_to :map
  has_many :notifications, as: :notifiable

  acts_as_votable

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
              scope: [:map_id, :user_id],
              strict: Exceptions::DuplicateReview
            }
  validates :map_id,
            presence: {
              strict: Exceptions::MapNotSpecified
            }
  validates :image_url,
            format: {
              allow_blank: true,
              with: /\A#{URI::regexp(%w(http https))}\z/,
              scrict: Exceptions::InvalidUri
            }
  validate :validate_spot

  FEED_PER_PAGE = 20

  scope :map_posts_for, lambda { |current_user|
    includes(:user, :map)
      .where(map_id: current_user.following_maps.ids)
  }

  scope :referenceable_by, lambda { |current_user|
    includes(:user, :map)
      .where(maps: { id: current_user.following_maps.ids })
      .or(includes(:user, :map).where(maps: { private: false }))
  }

  scope :latest_feed, lambda {
    where(created_at: 6.month.ago...Time.now).order(created_at: :desc).limit(FEED_PER_PAGE)
  }

  scope :feed_before, lambda { |created_at|
    where(created_at: 6.month.ago...Time.parse(created_at)).order(created_at: :desc).limit(FEED_PER_PAGE)
  }

  scope :user_feed, lambda {
    order(created_at: :desc).limit(FEED_PER_PAGE)
  }

  scope :user_feed_before, lambda { |created_at|
    where('reviews.created_at < ?', Time.parse(created_at)).order(created_at: :desc).limit(FEED_PER_PAGE)
  }

  scope :recent, lambda {
    includes(:user, :map).where(maps: { private: false }).order(created_at: :desc).limit(8)
  }

  def spot
    @spot ||= Spot.new(place_id_val, thumbnail_url)
  end

  def image_name
    return '' if image_url.blank?
    File.basename(CGI.unescape(image_url))
  end

  def thumbnail_url
    return '' if image_url.blank?
    parsed = URI.parse(image_url)
    "#{parsed.scheme}://#{parsed.host}#{File.dirname(parsed.path)}/images%2Fthumb_#{image_name}"
  end

  private

  def remove_carriage_return
    return unless comment
    comment.gsub!(/\r/, '')
  end

  def validate_spot
    raise Exceptions::PlaceNotFound if spot.name.blank?
  end
end
