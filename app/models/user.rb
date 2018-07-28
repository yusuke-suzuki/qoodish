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

require 'open-uri'

class User < ApplicationRecord
  has_many :devices, dependent: :destroy
  has_many :maps, dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_many :notifications, as: :recipient
  has_many :invites, as: :recipient

  validates :uid,
            presence: true
  validates :provider_uid,
            presence: true,
            uniqueness: true

  acts_as_follower
  acts_as_voter

  before_validation :fetch_github_user_id
  after_create :create_default_map
  before_destroy :delete_profile_image

  PROVIDER_GITHUB = 'github.com'.freeze
  PROVIDER_FACEBOOK = 'facebook.com'.freeze
  PROVIDER_ANONYMOUS = 'anonymous'.freeze

  attr_accessor :is_anonymous

  def self.sign_in_anonymously(payload)
    raise Exceptions::Unauthorized unless payload['provider_id'] == PROVIDER_ANONYMOUS
    User.new(
      uid: payload['user_id'],
      is_anonymous: true
    )
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

  def github_user?
    provider == PROVIDER_GITHUB
  end

  def facebook_user?
    provider == PROVIDER_FACEBOOK
  end

  def upload_profile_image(url)
    url = fetch_fb_prof_image if facebook_user?
    path = "profile_#{SecureRandom.uuid}.jpg"
    open(url, 'rb') do |data|
      put_to_s3(path, data)
    end
    update!(image_path: path)
  end

  def put_to_s3(key, body)
    client.put_object(
      bucket: ENV['S3_BUCKET_NAME'],
      key: key,
      body: body,
      acl: 'public-read',
      content_type: 'image/jpeg'
    )
  end

  def delete_from_s3(key)
    client.delete_object(
      bucket: ENV['S3_BUCKET_NAME'],
      key: key
    )
  end

  def fetch_fb_prof_image
    return unless facebook_user?
    prof = graph.get_connections('me', '?fields=name,link,picture')
    prof['picture']['data']['url']
  end

  def image_url
    if image_path.present?
      "#{ENV['S3_ENDPOINT']}/#{ENV['S3_BUCKET_NAME']}/#{image_path}"
    else
      ENV['SUBSTITUTE_URL']
    end
  end

  def delete_profile_image
    delete_from_s3(image_path)
  end

  def fetch_github_user_id
    return unless github_user? && name.blank?
    user = github_client.fetch_user(provider_token, provider_uid)
    self.name = user['login']
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

  def client
    @client ||= Aws::S3::Client.new(
      access_key_id: ENV['AWS_ACCESS_KEY'],
      secret_access_key: ENV['AWS_SECRET_KEY']
    )
  end

  def graph
    @graph ||= Koala::Facebook::API.new(provider_token)
  end

  def github_client
    @github_client ||= Github.new(endpoint: ENV['GITHUB_API_ENDPOINT'])
  end

  def iid_client
    @iid_client ||= GoogleIid.new(endpoint: ENV['GOOGLE_IID_ENDPOINT'])
  end

  def fcm_client
    @fcm_client ||= Fcm.new(endpoint: ENV['FCM_ENDPOINT'])
  end
end
