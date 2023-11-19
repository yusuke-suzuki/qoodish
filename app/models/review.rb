require 'google/cloud/storage'

class Review < ApplicationRecord
  belongs_to :user
  belongs_to :map
  has_many :images, dependent: :destroy
  has_many :notifications, as: :notifiable
  has_many :comments, as: :commentable
  has_many :votes, as: :votable, dependent: :destroy
  has_many :voters, through: :votes, source: :voter, source_type: User.name

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
  validates :map_id,
            presence: true
  validates :latitude,
            presence: true
  validates :longitude,
            presence: true
  validates :name,
            presence: true,
            length: {
              allow_blank: false,
              maximum: 100
            }

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

  def thumbnail_url(size = '200x200')
    images.exists? ? images.first.thumbnail_url(size) : ''
  end

  def lat
    latitude.to_f
  end

  def lng
    longitude.to_f
  end

  private

  def remove_carriage_return
    name.delete!("\r") if name.present?
    comment.delete!("\r") if comment.present?
  end
end
