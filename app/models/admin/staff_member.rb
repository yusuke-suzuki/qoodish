module Admin
  class StaffMember < ApplicationRecord
    has_many :staff_member_roles, dependent: :destroy, autosave: true
    has_many :roles, through: :staff_member_roles
    has_many :role_permissions, through: :roles
    has_many :moderation_decisions, dependent: :restrict_with_exception

    normalizes :email, with: ->(email) { email.strip.downcase }

    validates :email, presence: true, uniqueness: true
    validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
    validates :changed_by, exclusion: { in: ->(staff_member) { [staff_member] } }

    attr_accessor :changed_by

    scope :active, -> { where(revoked_at: nil) }

    before_update :unassign_all_roles, if: -> { revoked_at_changed?(from: nil) }

    def self.grant!(email:, role:)
      find_or_create_by!(email: email).tap { |staff_member| staff_member.grant!(role) }
    end

    def can?(permission)
      permissions.include?(permission)
    end

    def permissions
      @permissions ||= role_permissions.distinct.pluck(:permission).map(&:to_sym)
    end

    def grant!(role)
      staff_member_roles.find_or_initialize_by(role: role)
      update!(revoked_at: nil)
    end

    def unassign!(role, by:)
      assignment = staff_member_roles.detect { |staff_member_role| staff_member_role.role_id == role.id }
      raise ActiveRecord::RecordNotFound unless assignment

      assignment.mark_for_destruction
      update!(changed_by: by)
    end

    def revoke!(by:)
      update!(revoked_at: Time.current, changed_by: by)
    end

    private

    def unassign_all_roles
      staff_member_roles.destroy_all
    end
  end
end
