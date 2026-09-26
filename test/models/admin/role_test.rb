require 'test_helper'

class Admin::RoleTest < ActiveSupport::TestCase
  test 'a role accepts only permissions the admin API knows' do
    assert_raises(ActiveRecord::RecordInvalid) { roles(:reader).permit!('manage_everything') }
  end

  test 'permitting twice keeps one permission' do
    role = roles(:reader)

    assert_no_difference -> { role.role_permissions.count } do
      role.permit!(Admin::Permission::READ_REPORTS.to_s)
    end
  end

  test 'a role that members still hold cannot be deleted' do
    assert_raises(ActiveRecord::DeleteRestrictionError) { roles(:moderator).destroy! }
  end
end
