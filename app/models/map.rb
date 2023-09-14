class Map < ApplicationRecord
  belongs_to :user
  has_many :reviews, dependent: :destroy
  has_many :spots, dependent: :destroy
  has_many :notifications, as: :notifiable
  has_many :invites, as: :invitable, dependent: :destroy
  has_many :follows, as: :followable, dependent: :destroy
  has_many :followers, through: :follows, source: :follower, source_type: User.name
  has_many :votes, as: :votable, dependent: :destroy
  has_many :voters, through: :votes, source: :voter, source_type: User.name

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

  scope :with_deps, lambda {
    includes(%i[user votes voters])
  }

  scope :public_open, lambda {
    where(private: false)
  }

  scope :referenceable_by, lambda { |user|
    following_by(user)
      .group('maps.id')
      .or(unfollowing_by(user).public_open)
  }

  scope :postable_by, lambda { |user|
    following_by(user)
      .where(maps: { shared: true })
      .or(following_by(user).where(maps: { shared: false, user: user }))
  }

  scope :invitable_by, lambda { |user|
    joins(:follows)
      .where(maps: { user: user })
      .or(following_by(user).where(maps: { invitable: true }))
  }

  scope :following_by, lambda { |user|
    joins(:follows)
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
    return nil if base_id_val.blank?

    @base ||= Base.new(base_id_val)
  end

  def thumbnail_url(size = '200x200')
    return '' if image_url.blank?

    ext = File.extname(image_url)
    "#{ENV['CLOUD_STORAGE_ENDPOINT']}/#{ENV['CLOUD_STORAGE_BUCKET_NAME']}/maps/thumbnails/#{File.basename(image_name,
                                                                                                          ext)}_#{size}#{ext}"
  end

  def image_name
    return '' if image_url.blank?

    File.basename(CGI.unescape(image_url))
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
