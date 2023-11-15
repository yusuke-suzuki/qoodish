class NotificationsController < ApplicationController
  before_action :authenticate_user!

  def index
    @notifications =
      current_user
      .notifications
      .recent
      .includes(:notifier, :notifiable)
      .reject do |notification|
        notification.notifier.blank? || notification.notifiable.blank?
      end
  end

  def update
    @notification =
      current_user
      .notifications
      .find_by!(id: params[:id])

    @notification.update!(read: true)
  end
end
