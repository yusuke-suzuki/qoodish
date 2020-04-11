require 'google/cloud/storage'

class Review < ApplicationRecord
  belongs_to :user
  belongs_to :map
  belongs_to :spot
  has_many :images, dependent: :destroy
  has_many :notifications, as: :notifiable
  has_many :comments, as: :commentable
  has_many :votes, as: :votable, dependent: :destroy

  before_validation :remove_carriage_return
  before_validation :create_spot

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
  validates :spot_id,
            presence: true,
            uniqueness: {
              scope: %i[map_id user_id],
              strict: Exceptions::DuplicateReview
            }
  validates :map_id,
            presence: {
              strict: Exceptions::MapNotSpecified
            }

  FEED_PER_PAGE = 12

  scope :with_deps, lambda {
    includes(:map, :spot, :user, :comments, :images, :votes)
  }

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

  def name
    spot.name
  end

  def thumbnail_url(size = '200x200')
    images.exists? ? images.first.thumbnail_url(size) : ENV['SUBSTITUTE_URL']
  end

  private

  def remove_carriage_return
    return unless comment

    comment.delete!("\r")
  end

  def create_spot
    self.spot = Spot.find_or_create_by!(
      place_id_val: place_id_val,
      map: map
    )
  end
end
