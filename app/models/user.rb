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
  validates :image_path,
            presence: true,
            uniqueness: true

  after_create :create_default_map

  PROVIDER_ANONYMOUS = 'anonymous'.freeze

  attr_accessor :is_anonymous

  scope :search_by_name, lambda { |name|
    where('name LIKE ?', "%#{name}%")
      .limit(20)
  }

  def self.sign_in_anonymously(payload)
    raise Exceptions::Unauthorized unless payload['provider_id'] == PROVIDER_ANONYMOUS

    User.new(
      uid: payload['user_id'],
      is_anonymous: true
    )
  end

  def thumbnail_url
    return '' if image_path.blank?

    "#{ENV['CLOUD_STORAGE_ENDPOINT']}/#{ENV['CLOUD_STORAGE_BUCKET_NAME']}/profile/thumb_#{image_name}"
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
    votes.exists?(votable: votable)
  end

  def subscribe_topic(topic)
    registration_tokens = devices.pluck(:registration_token)
    if registration_tokens.blank?
      Rails.logger.info('User does not have registration tokens for subscribe topic.')
      return
    end

    GoogleIidClient.configure do |config|
      config.api_key['Authorization'] = "key=#{ENV['FCM_SERVER_KEY']}"
      config.debugging = Rails.env.development?
    end

    api_instance = GoogleIidClient::RelationshipMapsApi.new
    inline_object = GoogleIidClient::InlineObject.new(
      to: "/topics/#{topic}",
      registration_tokens: registration_tokens
    )

    begin
      result = api_instance.iid_v1batch_add_post(inline_object)
      Rails.logger.info(result)
    rescue GoogleIidClient::ApiError => e
      Rails.logger.error("Exception when calling RelationshipMapsApi->iid_v1batch_add_post: #{e}")
    end
  end

  def unsubscribe_topic(topic)
    registration_tokens = devices.pluck(:registration_token)
    if registration_tokens.blank?
      Rails.logger.info('User does not have registration tokens for unsubscribe topic.')
      return
    end

    GoogleIidClient.configure do |config|
      config.api_key['Authorization'] = "key=#{ENV['FCM_SERVER_KEY']}"
      config.debugging = Rails.env.development?
    end

    api_instance = GoogleIidClient::RelationshipMapsApi.new
    inline_object1 = GoogleIidClient::InlineObject1.new(
      to: "/topics/#{topic}",
      registration_tokens: registration_tokens
    )

    begin
      result = api_instance.iid_v1batch_remove_post(inline_object1)
      Rails.logger.info(result)
    rescue GoogleIidClient::ApiError => e
      Rails.logger.error("Exception when calling RelationshipMapsApi->iid_v1batch_remove_post: #{e}")
    end
  end

  def create_default_map
    maps.create!(
      name: "#{name}'s map",
      description: "#{name}'s map."
    )
  end
end
