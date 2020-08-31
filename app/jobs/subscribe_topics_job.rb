class SubscribeTopicsJob < ApplicationJob
  queue_as :default

  def perform(device_id)
    device = Device.find_by(id: device_id)
    return if device.blank?

    device.subscribe_topics
  end
end
