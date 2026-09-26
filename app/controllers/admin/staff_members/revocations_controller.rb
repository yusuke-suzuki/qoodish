module Admin
  module StaffMembers
    class RevocationsController < BaseController
      requires_permission Permission::MANAGE_STAFF, only: :create

      def create
        @staff_member = StaffMember.find(params[:staff_member_id])
        @staff_member.revoke!(by: current_staff_member)

        render 'admin/staff_members/show', status: :created
      end
    end
  end
end
