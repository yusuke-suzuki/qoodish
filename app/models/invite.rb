# == Schema Information
#
# Table name: invites
#
#  id             :integer          not null, primary key
#  invitable_type :string(255)
#  invitable_id   :integer
#  sender_type    :string(255)
#  sender_id      :integer
#  recipient_type :string(255)
#  recipient_id   :integer
#  expired        :boolean          default(FALSE)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_invites_on_invitable_id_and_invitable_type  (invitable_id,invitable_type)
#  index_invites_on_invitable_type_and_invitable_id  (invitable_type,invitable_id)
#  index_invites_on_recipient_id_and_recipient_type  (recipient_id,recipient_type)
#  index_invites_on_recipient_type_and_recipient_id  (recipient_type,recipient_id)
#  index_invites_on_sender_id_and_sender_type        (sender_id,sender_type)
#  index_invites_on_sender_type_and_sender_id        (sender_type,sender_id)
#

class Invite < ApplicationRecord
  belongs_to :invitable, polymorphic: true
  belongs_to :sender, polymorphic: true
  belongs_to :recipient, polymorphic: true

  def invitable_name
    case invitable_type
    when Map.name
      'map'
    else
      ''
    end
  end
end
