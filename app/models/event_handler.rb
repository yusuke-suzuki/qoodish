require 'base64'

class EventHandler
  def self.handle_event(action_type_base64, payload)
    action_type = Base64.decode64(action_type_base64)
    Rails.logger.info("[Event Handler] Handle event: #{action_type} #{payload}")

    case action_type
    when 'SUBSCRIBE_TOPICS'
      SubscribeTopicsJob.perform_later(payload['device_id'].to_i)
    when 'UNSUBSCRIBE_TOPICS'
      UnsubscribeTopicsJob.perform_later(payload['device_id'].to_i)
    else
      Rails.logger.warn("[Pub/Sub] Unknown action type received. End processing: #{action_type}")
    end
  rescue StandardError => e
    Rails.logger.fatal("[Pub/Sub] Failed to execute background job #{action_type}: #{e}")
  end
end
