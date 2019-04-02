module Jobs
  class SubscribeTopics
    def perform(payload)
      device = Device.find_by(id: payload['device_id'].to_i)
      return if device.blank?

      device.subscribe_topics
    end
  end
end
