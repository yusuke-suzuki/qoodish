module Me
  class NotificationsController < ApplicationController
    before_action :authenticate_user!

    def index
      @notification_groups =
        NotificationGroup.recent(
          current_user
          .notifications
          .renderable
          .not_blocking(current_user)
          .not_blocked_by(current_user)
          .not_muted_by(current_user)
        )
    end

    def update
      @notification =
        current_user
        .notifications
        .not_blocking(current_user)
        .not_blocked_by(current_user)
        .not_muted_by(current_user)
        .find_by!(id: params[:id])

      # The serialized payload needs both associations, so a notification
      # orphaned by their deletion is treated as missing, like in index.
      raise ActiveRecord::RecordNotFound unless @notification.renderable?

      @notification.read_with_earlier_in_group!
    end
  end
end
