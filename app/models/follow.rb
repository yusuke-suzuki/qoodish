class Follow < ApplicationRecord
  belongs_to :followable, polymorphic: true
  belongs_to :follower, polymorphic: true

  after_create :create_notification, unless: :followable_owner?
  after_create :subscribe_topic, if: :followable_type_map?
  before_destroy :unsubscribe_topic, if: :followable_type_map?

  def block!
    update!(blocked: true)
  end

  def followable_type_map?
    followable_type == Map.name
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

  def subscribe_topic
    follower.subscribe_topic("#{followable_type.downcase}_#{followable.id}")
  end

  def unsubscribe_topic
    follower.unsubscribe_topic("#{followable_type.downcase}_#{followable.id}")
  end
end
