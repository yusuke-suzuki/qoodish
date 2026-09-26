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

  test 'granting a role to a new email registers the staff member' do
    member = Admin::StaffMember.grant!(email: 'New@Example.com', role: roles(:reader))

    assert_equal 'new@example.com', member.email
    assert_equal [roles(:reader)], member.roles.to_a
  end

  test 'granting a role to a known email adds it to the existing member' do
    member = Admin::StaffMember.grant!(email: 'reader@example.com', role: roles(:moderator))

    assert_equal staff_members(:reader), member
    assert_equal [roles(:moderator), roles(:reader)], member.roles.sort_by(&:name)
  end

  test 'an email that is not an address is refused, in one Japanese sentence' do
    error = assert_raises(ActiveRecord::RecordInvalid) do
      Admin::StaffMember.grant!(email: 'not an address', role: roles(:reader))
    end

    assert error.record.errors.added?(:email, :invalid, value: 'not an address')
    I18n.with_locale(:ja) do
      assert_equal ['メールアドレスの形式が正しくありません。'], error.record.errors.full_messages
    end
  end

  test 'unassigning a role keeps the others' do
    member = staff_members(:reader)
    member.grant!(roles(:moderator))

    member.unassign!(roles(:reader))

    assert_equal [roles(:moderator)], member.roles.reload.to_a
  end

  test 'unassigning a role the member does not hold is not found' do
    assert_raises(ActiveRecord::RecordNotFound) { staff_members(:reader).unassign!(roles(:moderator)) }
  end

  test 'granting a role to a revoked member restores access' do
    member = staff_members(:revoked)
    member.grant!(roles(:moderator))

    assert_includes Admin::StaffMember.active, member
    assert_equal [roles(:moderator)], member.roles.to_a
  end
end
