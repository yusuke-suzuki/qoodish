class BloadcastWebPushJob < ApplicationJob
  queue_as :default

  def perform(notification)
    notification.bloadcast_web_push
  end
end
