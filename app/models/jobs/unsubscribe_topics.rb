module Jobs
  class UnsubscribeTopics
    def perform(payload)
      device = Device.find_by(id: payload['device_id'].to_i)
      return if device.blank?

      device.unsubscribe_topics
    end
  end
end
