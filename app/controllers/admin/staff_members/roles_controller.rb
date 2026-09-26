module Admin
  module StaffMembers
    class RolesController < BaseController
      requires_permission Permission::MANAGE_STAFF, only: :destroy

      def destroy
        @staff_member = StaffMember.find(params[:staff_member_id])
        @staff_member.unassign!(Role.find(params[:id]), by: current_staff_member)

        render 'admin/staff_members/show'
      end
    end
  end
end
