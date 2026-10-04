module V2
  module Me
    class NotificationsController < ApplicationController
      before_action :authenticate_user!

      def index
        @page =
          NotificationGroup.page(
            current_user
            .notifications
            .renderable
            .with_existing_notifier
            .not_blocking(current_user)
            .not_blocked_by(current_user)
            .not_muted_by(current_user)
            .preload({ notifier: :image }, notifiable: [:images, { commentable: :images }]),
            cursor: params[:cursor],
            unread: ActiveModel::Type::Boolean.new.cast(params[:read]) == false
          )
      end
    end
  end
end
