module Admin
  class StaffMembersController < BaseController
    requires_permission Permission::MANAGE_STAFF, only: %i[index create]

    def index
      @staff_members = StaffMember.preload(:roles).order(:email)
    end

    def create
      role = Role.find(staff_member_params[:role_id])
      @staff_member = StaffMember.grant!(email: staff_member_params[:email], role: role)

      render :show, status: :created
    end

    private

    def staff_member_params
      params.permit(:email, :role_id)
    end
  end
end
