module Users
  class PushNotificationsController < ApplicationController
    before_action :authenticate_user!

    def update
      push_notification = PushNotification.find_or_initialize_by(user: current_user)

      push_notification.update!(
        followed: params[:followed],
        invited: params[:invited],
        liked: params[:liked],
        comment: params[:comment]
      )
    end
  end
end
