module Admin
  class RolePermission < ApplicationRecord
    belongs_to :role

    validates :permission, inclusion: { in: Permission::ALL.map(&:to_s) }, uniqueness: { scope: :role_id }
  end
end
