class Device < ApplicationRecord
  belongs_to :user

  validates :user_id,
            presence: true
  validates :registration_token,
            presence: {
              strict: Exceptions::RegistrationTokenNotSpecified
            },
            uniqueness: {
              scope: :user_id,
              strict: Exceptions::DuplicateRegistrationToken
            }

  after_create :subscribe_topics_later
  before_destroy :unsubscribe_topics_later

  def related_topics
    topics = ["user_#{user_id}"]
    map_topics = user.following_maps.map do |map|
      "map_#{map.id}"
    end
    topics += map_topics
  end

  def subscribe_topics
    related_topics.each do |topic|
      result = iid_client.iid_v1_iid_token_rel_topics_topic_name_post(registration_token, topic)
      Rails.logger.info(result)
    rescue GoogleIidClient::ApiError => e
      Rails.logger.error("Exception when calling RelationshipMapsApi->iid_v1batch_remove_post: #{e}")
    end
  end

  def unsubscribe_topics
    related_topics.each do |topic|
      result = iid_client.iid_v1_iid_token_rel_topics_topic_name_delete(registration_token, topic)
      Rails.logger.info(result)
    rescue GoogleIidClient::ApiError => e
      Rails.logger.error("Exception when calling RelationshipMapsApi->iid_v1batch_remove_post: #{e}")
    end
  end

  private

  def iid_client
    GoogleIidClient.configure do |config|
      config.api_key['Authorization'] = "key=#{ENV['FCM_SERVER_KEY']}"
      config.debugging = Rails.env.development?
    end

    @iid_client ||= GoogleIidClient::RelationshipMapsApi.new
  end

  def subscribe_topics_later　
    PubSub.publish('SUBSCRIBE_TOPICS', device_id: id)
  end

  def unsubscribe_topics_later
    PubSub.publish('UNSUBSCRIBE_TOPICS', device_id: id)
  end
end
