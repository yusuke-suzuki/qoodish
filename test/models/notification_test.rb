# == Schema Information
#
# Table name: notifications
#
#  id              :integer          not null, primary key
#  notifiable_type :string(255)
#  notifiable_id   :integer
#  notifier_type   :string(255)
#  notifier_id     :integer
#  recipient_type  :string(255)
#  recipient_id    :integer
#  key             :string(255)
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

require 'test_helper'

class NotificationTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
