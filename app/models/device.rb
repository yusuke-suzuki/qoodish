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

  after_create :subscribe_topics
  before_destroy :unsubscribe_topics

  private

  def topics
    topics = ["user_#{user_id}"]
    map_topics = user.following_maps.map do |map|
      "map_#{map.id}"
    end
    topics += map_topics
  end

  def subscribe_topics
    GoogleIidClient.configure do |config|
      config.api_key['Authorization'] = "key=#{ENV['FCM_SERVER_KEY']}"
      config.debugging = Rails.env.development?
    end

    api_instance = GoogleIidClient::RelationshipMapsApi.new

    topics.each do |topic|
      begin
        result = api_instance.iid_v1_iid_token_rel_topics_topic_name_post(registration_token, topic)
        Rails.logger.info(result)
      rescue GoogleIidClient::ApiError => e
        Rails.logger.error("Exception when calling RelationshipMapsApi->iid_v1batch_remove_post: #{e}")
      end
    end
  end

  def unsubscribe_topics
    GoogleIidClient.configure do |config|
      config.api_key['Authorization'] = "key=#{ENV['FCM_SERVER_KEY']}"
      config.debugging = Rails.env.development?
    end

    api_instance = GoogleIidClient::RelationshipMapsApi.new

    topics.each do |topic|
      begin
        result = api_instance.iid_v1_iid_token_rel_topics_topic_name_delete(registration_token, topic)
        Rails.logger.info(result)
      rescue GoogleIidClient::ApiError => e
        Rails.logger.error("Exception when calling RelationshipMapsApi->iid_v1batch_remove_post: #{e}")
      end
    end
  end
end
