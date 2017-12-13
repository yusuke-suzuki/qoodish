# == Schema Information
#
# Table name: notifications
#
#  id              :integer          not null, primary key
#  notifiable_type :string
#  notifiable_id   :integer
#  notifier_type   :string
#  notifier_id     :integer
#  recipient_type  :string
#  recipient_id    :integer
#  key             :string
#  read            :boolean          default(FALSE)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_notifications_on_notifiable_id_and_notifiable_type  (notifiable_id,notifiable_type)
#  index_notifications_on_notifiable_type_and_notifiable_id  (notifiable_type,notifiable_id)
#  index_notifications_on_notifier_id_and_notifier_type      (notifier_id,notifier_type)
#  index_notifications_on_notifier_type_and_notifier_id      (notifier_type,notifier_id)
#  index_notifications_on_recipient_id_and_recipient_type    (recipient_id,recipient_type)
#  index_notifications_on_recipient_type_and_recipient_id    (recipient_type,recipient_id)
#

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
    else
      ''
    end
  end

  def click_action
    case notifiable_type
    when Review.name
      "/maps/#{notifiable.map_id}/reports/#{notifiable.id}"
    when Map.name
      "/maps/#{notifiable.id}"
    else
      ''
    end
  end
end
