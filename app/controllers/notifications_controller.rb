class NotificationsController < ApplicationController
  before_action :authenticate_user!

  def index
    @notifications = current_user.notifications.recent(current_user).reject { |notification| notification.notifier.blank? || notification.notifier.blank? }
  end

  def update
    @notification = current_user.notifications.find_by!(id: params[:id])
    @notification.update!(read: true)
  end
end
