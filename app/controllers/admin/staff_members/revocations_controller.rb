module Admin
  module StaffMembers
    class RevocationsController < BaseController
      requires_permission Permission::MANAGE_STAFF, only: :create

      def create
        @staff_member = other_staff_member(params[:staff_member_id])
        @staff_member.revoke!

        render 'admin/staff_members/show', status: :created
      end
    end
  end
end
