class BroadcastWebPushJob < ApplicationJob
  queue_as :default

  def perform(notification)
    notification.broadcast_web_push
  end
end
