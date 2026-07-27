module Users
  class PushNotificationsController < ApplicationController
    before_action :authenticate_user!

    def update
      current_user.update_web_push_preferences!(push_notification_params)
    end

    private

    def push_notification_params
      params
        .permit(:coauthor_invited, :liked, :comment, :published)
        .to_h
    end
  end
end
