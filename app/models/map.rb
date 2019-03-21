class Map < ApplicationRecord
  belongs_to :user
  has_many :reviews, dependent: :destroy
  has_many :notifications, as: :notifiable
  has_many :invites, as: :invitable, dependent: :destroy
  has_many :follows, as: :followable, dependent: :destroy
  has_many :followers, through: :follows, source: :follower, source_type: User.name
  has_many :votes, as: :votable, dependent: :destroy

  attr_accessor :base_lat, :base_lng

  validates :name,
            presence: {
              strict: Exceptions::MapNameNotSpecified
            },
            uniqueness: {
              scope: :user_id,
              strict: Exceptions::DuplicateMapName,
              on: :create
            },
            length: {
              allow_blank: false,
              maximum: 30,
              strict: Exceptions::MapNameExceeded
            }
  validates :description,
            presence: {
              strict: Exceptions::MapDescriptionNotSpecified
            },
            length: {
              allow_blank: false,
              maximum: 200,
              strict: Exceptions::MapDescriptionExceeded
            }
  validates :user_id,
            presence: {
              strict: Exceptions::MapOwnerNotSpecified
            }

  before_validation :remove_carriage_return
  after_create :follow_by_owner

  scope :public_open, lambda {
    where(private: false)
  }

  scope :referenceable_by, lambda { |user|
    following_by(user)
      .or(unfollowing_by(user).public_open)
  }

  scope :postable_by, lambda { |user|
    joins(:follows)
      .where(maps: { user: user })
      .or(following_by(user).where(maps: { shared: true }))
  }

  scope :invitable_by, lambda { |user|
    joins(:follows)
      .where(maps: { user: user })
      .or(following_by(user).where(maps: { invitable: true }))
  }

  scope :following_by, lambda { |user|
    joins(:follows)
      .group('maps.id')
      .where(follows: { follower: user })
  }

  scope :unfollowing_by, lambda { |user|
    joins(:follows)
      .group('maps.id')
      .having('count(follows.follower_id = ? or null) < 1', user.id)
  }

  scope :active, lambda {
    left_joins(:reviews)
      .group('maps.id')
      .order('max(reviews.created_at) desc')
      .limit(12)
  }

  scope :popular, lambda {
    joins(:follows)
      .group('maps.id')
      .order('count(follows.id) desc')
      .limit(10)
  }

  scope :search_by_words, lambda { |words|
    all.tap do |q|
      words.each { |word| q.where!('name LIKE :word', word: "%#{sanitize_sql_like(word)}%") }
    end
  }

  def base
    @base ||= Spot.new(base_id_val)
  end

  def spots
    reviews.order(created_at: :desc).group_by(&:place_id_val).map { |_key, value| value[0].spot }
  end

  def image_url
    reviews.exists? && reviews[0].image_url.present? ? reviews[0].image_url : ENV['SUBSTITUTE_URL']
  end

  def thumbnail_url
    reviews.exists? && reviews[0].image_url.present? ? reviews[0].thumbnail_url : ENV['SUBSTITUTE_URL']
  end

  private

  def remove_carriage_return
    name.delete!("\r") if name
    description.delete!("\r") if description
  end

  def follow_by_owner
    user.follow!(self)
  end
end
