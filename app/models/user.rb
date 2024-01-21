class User < ApplicationRecord
  has_many :devices, dependent: :destroy
  has_many :maps, dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_many :notifications, as: :recipient
  has_many :comments, dependent: :destroy
  has_many :invites, as: :recipient
  has_many :follows, as: :follower, dependent: :destroy
  has_many :votes, as: :voter, dependent: :destroy
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

  after_create :create_default_map

  scope :search_by_name, lambda { |name|
    where('name LIKE ?', "%#{name}%")
      .limit(20)
  }

  def thumbnail_url(size = '200x200')
    return '' if image_path.blank?

    ext = File.extname(image_path)
    "#{ENV['CLOUD_STORAGE_ENDPOINT']}/#{ENV['CLOUD_STORAGE_BUCKET_NAME']}/profile/thumbnails/#{File.basename(
      image_name, ext
    )}_#{size}#{ext}"
  end

  def image_name
    return '' if image_path.blank?

    File.basename(CGI.unescape(image_path))
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

  def create_default_map
    maps.create!(
      name: "#{name}'s map",
      description: "#{name}'s map."
    )
  end
end
