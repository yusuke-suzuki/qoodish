# == Schema Information
#
# Table name: users
#
#  id             :integer          not null, primary key
#  name           :string(255)
#  email          :string(255)
#  uid            :string(255)      not null
#  provider       :string(255)      not null
#  provider_uid   :string(255)      not null
#  provider_token :string(255)
#  image_path     :string(255)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_users_on_provider_and_provider_uid  (provider,provider_uid) UNIQUE
#  index_users_on_uid                        (uid)
#

class User < ApplicationRecord
  has_many :devices, dependent: :destroy
  has_many :maps, dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_many :notifications, as: :recipient
  has_many :invites, as: :recipient

  validates :uid,
            presence: true,
            uniqueness: true
  validates :name,
            presence: true
  validates :image_path,
            presence: true,
            uniqueness: true

  acts_as_follower
  acts_as_voter

  after_create :create_default_map

  PROVIDER_ANONYMOUS = 'anonymous'.freeze

  attr_accessor :is_anonymous

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

  def author?(review)
    review.user_id == id
  end

  def map_owner?(map)
    map.user_id == id
  end

  def postable?(map)
    map_owner?(map) || (map.shared && !map.private) || (map.private && following?(map) && map.shared)
  end

  def referenceable?(map)
    map_owner?(map) || following?(map) || (!following?(map) && !map.private)
  end

  def subscribe_topic(topic)
    registration_tokens = devices.pluck(:registration_token)
    return if registration_tokens.blank?
    iid_client.bulk_subscribe_topic(registration_tokens, topic)
  end

  def unsubscribe_topic(topic)
    registration_tokens = devices.pluck(:registration_token)
    return if registration_tokens.blank?
    iid_client.bulk_unsubscribe_topic(registration_tokens, topic)
  end

  def send_message_to_topic(topic, message, request_path, image = nil, data = {})
    fcm_client.send_message_to_topic(topic, message, request_path, image, data)
  end

  def unfollow_all_maps
    following_maps.each do |map|
      stop_following(map)
      unsubscribe_topic("map_#{map.id}")
    end
  end

  def create_default_map
    map = maps.create!(
      name: "#{name}'s map",
      description: "#{name}'s map."
    )
    follow(map)
    subscribe_topic("map_#{map.id}")
  end

  private

  def iid_client
    @iid_client ||= GoogleIid.new(endpoint: ENV['GOOGLE_IID_ENDPOINT'])
  end

  def fcm_client
    @fcm_client ||= Fcm.new(endpoint: ENV['FCM_ENDPOINT'])
  end
end
