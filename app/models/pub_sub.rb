require 'google/cloud/pubsub'

class PubSub
  PUBSUB_SCOPES = [
    'https://www.googleapis.com/auth/cloud-platform',
    'https://www.googleapis.com/auth/pubsub'
  ].freeze

  def initialize; end

  def publish(action_type, payload)
    Rails.logger.info("[Pub/Sub] Enqueue job: #{action_type} #{payload}")

    message = topic.publish(action_type, payload)

    Rails.logger.info("[Pub/Sub] Published message: #{message.inspect}")
  end

  private

  def pubsub
    @pubsub ||= Google::Cloud::PubSub.new(
      credentials: Google::Auth::ServiceAccountCredentials.make_creds(
        scope: PUBSUB_SCOPES
      )
    )
  end

  def topic
    @topic ||= pubsub.topic(ENV['PUBSUB_TOPIC'])
  end
end
