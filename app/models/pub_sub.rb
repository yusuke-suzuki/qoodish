require 'google/cloud/pubsub'

class PubSub
  def self.pubsub
    @pubsub ||= Google::Cloud::PubSub.new(
      project_id: ENV['GCP_PROJECT_ID'],
      credentials: Rails.root.join('gcp-pubsub-credentials.json')
    )
  end

  def self.topic
    @topic ||= pubsub.topic(ENV['PUBSUB_TOPIC'])
  end

  def self.subscription
    @subscription ||= pubsub.subscription(ENV['PUBSUB_SUBSCRIPTION'])
  end

  def self.publish(action_type, payload)
    Rails.logger.info("[Pub/Sub] Enqueue job: #{action_type} #{payload}")

    message = topic.publish(action_type, payload)
    Rails.logger.info("[Pub/Sub] Published message: #{message.inspect}")
  end

  def self.run_subscriber!
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
