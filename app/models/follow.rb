class Follow < ApplicationRecord
  belongs_to :followable, polymorphic: true
  belongs_to :follower, polymorphic: true

  after_create :create_notification, unless: :followable_owner?

  def block!
    update!(blocked: true)
  end

  def followable_owner?
    follower_id == followable.user_id
  end

  private

  def create_notification
    Notification.create!(
      notifiable: followable,
      notifier: follower,
      recipient: followable.user,
      key: 'followed'
    )
  end
end
