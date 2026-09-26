module Admin
  module StaffMembers
    class RolesController < BaseController
      requires_permission Permission::MANAGE_STAFF, only: :destroy

      def destroy
        @staff_member = other_staff_member(params[:staff_member_id])
        @staff_member.unassign!(Role.find(params[:id]))

        render 'admin/staff_members/show'
      end
    end
  end
end
