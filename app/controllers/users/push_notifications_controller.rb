module Users
  class PushNotificationsController < ApplicationController
    before_action :authenticate_user!

    def update
      push_notification = PushNotification.find_or_initialize_by(user: current_user)

      push_notification.update!(push_notification_params)
    end

    private

    def push_notification_params
      params
        .permit(:followed, :liked, :comment)
        .to_h
    end
  end
end
