class EventHandler
  def self.handle_event(action_type, payload)
    Rails.logger.info("[Event Handler] Handle event: #{action_type} #{payload}")

    job = detect_job(action_type)

    if job.blank?
      Rails.logger.warn("[Pub/Sub] Unknown action type received. End processing: #{action_type}")
      return
    end

    job.perform(payload)
  rescue StandardError => e
    Rails.logger.fatal("[Pub/Sub] Failed to execute background job #{action_type}: #{e}")
  end

  private

  def self.detect_job(action_type)
    case action_type
    when 'SUBSCRIBE_TOPICS'
      Jobs::SubscribeTopics.new
    when 'UNSUBSCRIBE_TOPICS'
      Jobs::UnsubscribeTopics.new
    end
  end
end
