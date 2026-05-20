class User < ApplicationRecord
  self.ignored_columns = %w[image_path]

  has_many :devices, dependent: :destroy
  has_many :maps, dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_many :notifications, as: :recipient
  has_many :comments, dependent: :destroy
  has_many :invites, as: :recipient
  has_many :follows, as: :follower, dependent: :destroy
  has_many :votes, as: :voter, dependent: :destroy
  has_many :owned_images, class_name: 'Image', dependent: :destroy
  has_many :images, as: :imageable, dependent: :destroy
  has_one :push_notification, dependent: :destroy

  validates :uid,
            presence: true,
            uniqueness: true
  validates :name,
            presence: true
  validates :biography,
            length: {
              allow_blank: true,
              maximum: 160
            }
  validates :images, length: { maximum: 1 }

  before_destroy :delete_id_platform_account
  after_create :create_default_map

  scope :search_by_name, lambda { |name|
    where('name LIKE ?', "%#{name}%")
      .limit(20)
  }

  def thumbnail_url(size = '200x200')
    primary = images.first
    return '' if primary&.url.blank?
    return Cloudflare::Images.variant_url_for_legacy_size(primary.url, size) if primary.url.include?(Cloudflare::Images::DELIVERY_HOST)

    ext = File.extname(primary.url)
    "#{ENV['CLOUD_STORAGE_ENDPOINT']}/#{ENV['CLOUD_STORAGE_BUCKET_NAME']}/profile/thumbnails/" \
      "#{File.basename(File.basename(CGI.unescape(primary.url)), ext)}_#{size}#{ext}"
  end

  def image_url
    images.first&.url.to_s
  end

  def image_variants
    primary = images.first
    return nil unless primary

    if primary.url.include?(Cloudflare::Images::DELIVERY_HOST)
      Cloudflare::Images::NAMED_VARIANTS
        .index_with { |variant| Cloudflare::Images.variant_url(primary.url, variant) }
        .merge(url: primary.url)
    else
      {
        url: primary.url,
        avatar: thumbnail_url('200x200'),
        card: thumbnail_url('400x400'),
        hero: thumbnail_url('800x800'),
        ogp: primary.url
      }
    end
  end

  def author?(post)
    post.user_id == id
  end

  def map_owner?(map)
    map.user_id == id
  end

  def postable?(map)
    map_owner?(map) || (following?(map) && map.shared)
  end

  def referenceable_maps
    Map.referenceable_by(self)
  end

  def referenceable_reviews
    Review.referenceable_by(self)
  end

  def postable_maps
    Map.postable_by(self)
  end

  def invitable_maps
    Map.invitable_by(self)
  end

  def following_maps
    Map.following_by(self)
  end

  def following?(followable)
    follows.exists?(followable: followable)
  end

  def follow_count
    follows.where(follower: self).size
  end

  def follow!(followable)
    follows.create!(followable: followable)
  end

  def unfollow!(followable)
    follows.find_by!(followable: followable).destroy!
  end

  def referenceable_vote?(vote)
    return false if vote.votable.blank?

    case vote.votable_type
    when Comment.name
      false
    when Review.name
      referenceable_reviews.exists?(vote.votable.id)
    when Map.name
      referenceable_maps.exists?(vote.votable.id)
    else
      true
    end
  end

  def liked!(votable)
    votes.create!(votable: votable)
  end

  def unliked!(votable)
    votes.find_by!(votable: votable).destroy!
  end

  def liked?(votable)
    votable.voters.any? { |voter| voter.id == id }
  end

  private

  def delete_id_platform_account
    id_platform.delete_account(uid)
  end

  def id_platform
    @id_platform ||= IdentityPlatform.new
  end

  def create_default_map
    maps.create!(
      name: "#{name}'s map",
      description: "#{name}'s map."
    )
  end
end
