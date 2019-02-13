class Notification < ApplicationRecord
  belongs_to :notifiable, polymorphic: true
  belongs_to :notifier, polymorphic: true
  belongs_to :recipient, polymorphic: true

  scope :recent, lambda { |current_user|
    includes(:notifier, :notifiable).where.not(notifications: { notifier_id: current_user.id }).order(created_at: :desc).limit(10)
  }

  def notifiable_name
    case notifiable_type
    when Review.name
      'report'
    when Map.name
      'map'
    when Comment.name
      'comment'
    else
      ''
    end
  end

  def click_action
    if key == 'invited'
      return '/invites'
    end

    case notifiable_type
    when Comment.name
      "/maps/#{notifiable.commentable.map_id}/reports/#{notifiable.commentable.id}"
    when Review.name
      "/maps/#{notifiable.map_id}/reports/#{notifiable.id}"
    when Map.name
      "/maps/#{notifiable.id}"
    else
      ''
    end
  end
end
