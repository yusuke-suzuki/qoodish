module Admin
  class StaffMemberRole < ApplicationRecord
    belongs_to :staff_member
    belongs_to :role

    validates :role_id, uniqueness: { scope: :staff_member_id }
  end
end
