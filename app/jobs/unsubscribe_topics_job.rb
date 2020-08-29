class UnsubscribeTopicsJob < ApplicationJob
  queue_as :default

  def perform(device_id)
    device = Device.find_by(id: device_id)
    return if device.blank?

    device.unsubscribe_topics
  end
end
