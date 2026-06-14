class Map < ApplicationRecord
  belongs_to :user
  has_many :reviews, dependent: :destroy
  has_many :notifications, as: :notifiable
  has_many :invites, as: :invitable, dependent: :destroy
  has_many :follows, as: :followable, dependent: :destroy
  has_many :followers, through: :follows, source: :follower, source_type: User.name
  has_many :votes, as: :votable, dependent: :destroy
  has_many :voters, through: :votes, source: :voter, source_type: User.name
  has_many :images, as: :imageable, dependent: :destroy

  validates :name,
            presence: {
              message: I18n.t('messages.api.map_name_required')
            },
            uniqueness: {
              scope: :user_id,
              message: I18n.t('messages.api.duplicate_map_name'),
              on: :create
            },
            length: {
              allow_blank: false,
              maximum: 30,
              message: I18n.t('messages.api.map_name_exceed')
            }
  validates :description,
            presence: {
              message: I18n.t('messages.api.map_description_required')
            },
            length: {
              allow_blank: false,
              maximum: 200,
              message: I18n.t('messages.api.map_description_exceed')
            }
  validates :user_id,
            presence: {
              message: I18n.t('messages.api.map_owner_not_specified')
            }
  validates :images, length: { maximum: 1 }

  before_validation :remove_carriage_return
  after_create :follow_by_owner

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

  def image_url
    images.first&.url.to_s
  end

  def image_variants
    primary = images.first
    return nil unless primary

    Cloudflare::Images::NAMED_VARIANTS
      .index_with { |variant| Cloudflare::Images.variant_url(primary.url, variant) }
      .merge(url: primary.url)
  end

  def lat
    latitude.to_f
  end

  def lng
    longitude.to_f
  end

  private

  def remove_carriage_return
    name&.delete!("\r")
    description&.delete!("\r")
  end

  def follow_by_owner
    user.follow!(self)
  end
end
