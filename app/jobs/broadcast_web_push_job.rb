class BroadcastWebPushJob < ApplicationJob
  queue_as :default

  def perform(notification)
    return unless notification.allowed_web_push?

    notification.broadcast_web_push
  end
end
