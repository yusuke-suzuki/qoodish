require 'google/cloud/pubsub'

class PubSub
  PUBSUB_SCOPES = [
    'https://www.googleapis.com/auth/cloud-platform',
    'https://www.googleapis.com/auth/pubsub'
  ].freeze

  def initialize
  end

  def publish(action_type, payload)
    Rails.logger.info("[Pub/Sub] Enqueue job: #{action_type} #{payload}")

    message = topic.publish(action_type, payload)

    Rails.logger.info("[Pub/Sub] Published message: #{message.inspect}")
  end

  def run_subscriber!
    Rails.logger.info('[Pub/Sub] Start running subscriber')

    subscriber = subscription.listen do |received_message|
      received_message.acknowledge!
      Rails.logger.info("[Pub/Sub] Message received at #{Time.now}: #{received_message.inspect}")

      EventHandler.handle_event(received_message.data, received_message.attributes)
    end

    subscriber.on_error do |error|
      Rails.logger.fatal("[Pub/Sub] Unhandled errors occurred on subscriber: #{error}")
    end

    subscriber.start

    # Fade into a deep sleep as worker will run indefinitely
    sleep
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

  def subscription
    @subscription ||= pubsub.subscription(ENV['PUBSUB_SUBSCRIPTION'])
  end
end

module SubscriberLogger
  LOGGER = Rails.logger

  def logger
    LOGGER
  end
end

module GRPC
  extend SubscriberLogger
end
