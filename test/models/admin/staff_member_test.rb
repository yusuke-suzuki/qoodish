require 'test_helper'

class Admin::StaffMemberTest < ActiveSupport::TestCase
  test 'a staff member holds the permissions of its roles' do
    member = staff_members(:reader)

    assert member.can?(Admin::Permission::READ_REPORTS)
    assert_not member.can?(Admin::Permission::DECIDE_REPORTS)
  end

  test 'permissions from several roles add up' do
    member = staff_members(:reader)
    member.grant!(roles(:moderator))

    assert Admin::StaffMember.find(member.id).can?(Admin::Permission::DECIDE_REPORTS)
  end

  test 'a staff member without roles holds no permission' do
    member = Admin::StaffMember.create!(email: 'new@example.com')

    Admin::Permission::ALL.each { |permission| assert_not member.can?(permission) }
  end

  test 'an email is found regardless of case' do
    assert_equal staff_members(:moderator), Admin::StaffMember.active.find_by(email: 'Moderator@Example.com')
  end

  test 'revoking keeps the record and ends its access' do
    member = staff_members(:moderator)
    member.revoke!

    assert_not_includes Admin::StaffMember.active, member
    assert Admin::StaffMember.exists?(member.id)
  end

  test 'granting a role to a revoked member restores access' do
    member = staff_members(:revoked)
    member.grant!(roles(:moderator))

    assert_includes Admin::StaffMember.active, member
    assert_equal [roles(:moderator)], member.roles.to_a
  end
end
