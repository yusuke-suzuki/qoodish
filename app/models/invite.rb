class Invite < ApplicationRecord
  belongs_to :invitable, polymorphic: true
  belongs_to :sender, polymorphic: true
  belongs_to :recipient, polymorphic: true

  after_create :create_notification

  def invitable_name
    case invitable_type
    when Map.name
      'map'
    else
      ''
    end
  end

  private

  def create_notification
    Notification.create!(
      notifiable: invitable,
      notifier: sender,
      recipient: recipient,
      key: 'invited'
    )
  end
end
