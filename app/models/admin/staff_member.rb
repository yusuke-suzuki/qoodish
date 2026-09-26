module Admin
  class StaffMember < ApplicationRecord
    has_many :staff_member_roles, dependent: :destroy
    has_many :roles, through: :staff_member_roles
    has_many :role_permissions, through: :roles
    has_many :moderation_decisions, dependent: :restrict_with_exception

    normalizes :email, with: ->(email) { email.strip.downcase }

    validates :email, presence: true, uniqueness: true

    scope :active, -> { where(revoked_at: nil) }

    def can?(permission)
      permissions.include?(permission)
    end

    def permissions
      @permissions ||= role_permissions.distinct.pluck(:permission).map(&:to_sym)
    end

    def grant!(role)
      transaction do
        update!(revoked_at: nil)
        roles << role unless roles.include?(role)
      end
    end

    def revoke!
      update!(revoked_at: Time.current)
    end
  end
end
