module Admin
  class Role < ApplicationRecord
    has_many :role_permissions, dependent: :destroy
    has_many :staff_member_roles, dependent: :restrict_with_exception
    has_many :staff_members, through: :staff_member_roles

    validates :name, presence: true, uniqueness: true

    def permit!(permission)
      role_permissions.find_or_create_by!(permission: permission)
    end
  end
end
