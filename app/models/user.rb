class User < ApplicationRecord
  has_many :devices, dependent: :destroy
  has_many :maps, dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_many :notifications, as: :recipient
  has_many :comments, dependent: :destroy
  has_many :invites, as: :recipient

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

  acts_as_follower
  acts_as_voter

  after_create :create_default_map

  PROVIDER_ANONYMOUS = 'anonymous'.freeze
  FCM_SCOPE = 'https://www.googleapis.com/auth/firebase.messaging'.freeze

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

  def author?(post)
    post.user_id == id
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

  def send_message_to_topic(topic, body, request_path, image = nil, data = {})
    FcmClient.configure do |config|
      config.api_key['Authorization'] = authenticate_firebase_admin
      config.api_key_prefix['Authorization'] = 'Bearer'
      config.debugging = Rails.env.development?
    end
    api_instance = FcmClient::MessagesApi.new

    notification = FcmClient::Notification.new(
      title: 'Qoodish',
      body: body,
      icon: ENV['SUBSTITUTE_URL'],
      click_action: "#{ENV['WEB_ENDPOINT']}/#{request_path}"
    )
    notification.image = image if image.present?
    notification.data = data if data.present?

    message = FcmClient::Message.new(
      topic: topic,
      webpush: {
        notification: notification
      }
    )
    inline_object = FcmClient::InlineObject.new(message: message)

    begin
      result = api_instance.v1_projects_project_id_messagessend_post(ENV['FIREBASE_PROJECT_ID'], inline_object)
      Rails.logger.info(result)
    rescue FcmClient::ApiError => e
      Rails.logger.error("Exception when calling MessagesApi->v1_projects_project_id_messagessend_post: #{e}")
    end
  end

  def authenticate_firebase_admin
    authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open(Rails.root.join('firebase-credentials.json')),
      scope: FCM_SCOPE
    )
    token = authorizer.fetch_access_token!
    token['access_token']
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
end
