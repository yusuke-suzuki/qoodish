# == Schema Information
#
# Table name: users
#
#  id             :integer          not null, primary key
#  name           :string
#  email          :string
#  uid            :string           not null
#  provider       :string           not null
#  provider_uid   :string           not null
#  provider_token :string
#  image_path     :string
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

  validates :uid,
            presence: true
  validates :provider_uid,
            presence: true,
            uniqueness: true

  acts_as_follower

  before_validation :fetch_github_user_id
  before_destroy :delete_profile_image

  PROVIDER_GITHUB = 'github.com'.freeze
  PROVIDER_FACEBOOK = 'facebook.com'.freeze

  def author?(review)
    review.user_id == id
  end

  def map_owner?(map)
    map.user_id == id
  end

  def postable?(map)
    following?(map) && (map_owner?(map) || map.shared)
  end

  def referenceable?(map)
    following?(map) || (!following?(map) && !map.private)
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
    devices.each do |device|
      iid_client.subscribe_topic(device.registration_token, topic)
    end
  end

  def unsubscribe_topic(topic)
    devices.each do |device|
      iid_client.unsubscribe_topic(device.registration_token, topic)
    end
  end

  def send_message_to_topic(topic, message,request_path)
    fcm_client.send_message_to_topic(topic, message, request_path)
  end

  def unfollow_all_maps
    following_maps.each do |map|
      stop_following(map)
      unsubscribe_topic("map_#{map.id}")
    end
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
