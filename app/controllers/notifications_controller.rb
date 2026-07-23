class NotificationsController < ApplicationController
  before_action :authenticate_user!

  def index
    @notifications =
      current_user
      .notifications
      .recent
      .includes({ notifier: :images }, :notifiable)
      .reject do |notification|
        notification.notifier.blank? || notification.notifiable.blank?
      end

    preload_notifiable_images(@notifications)
  end

  def update
    @notification =
      current_user
      .notifications
      .find_by!(id: params[:id])

    @notification.update!(read: true)
  end

  private

  # Polymorphic preload: `includes(notifiable: :images)` cannot work because
  # Comment and Chapter have no :images association of their own (they serve
  # images via commentable / map). Group notifiables by type and preload
  # appropriately.
  def preload_notifiable_images(notifications)
    notifiables = notifications.map(&:notifiable)
    direct = notifiables.reject { |n| n.is_a?(Comment) || n.is_a?(Chapter) }
    comments = notifiables.select { |n| n.is_a?(Comment) }
    chapters = notifiables.select { |n| n.is_a?(Chapter) }

    if direct.any?
      ActiveRecord::Associations::Preloader.new(records: direct, associations: :images).call
    end

    if comments.any?
      ActiveRecord::Associations::Preloader.new(records: comments, associations: { commentable: :images }).call
    end

    if chapters.any?
      ActiveRecord::Associations::Preloader.new(records: chapters, associations: { map: :images }).call
    end
  end
end
