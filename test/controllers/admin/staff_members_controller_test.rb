require 'test_helper'

class Admin::StaffMembersControllerTest < ActionDispatch::IntegrationTest
  ACCESS_HEADERS = { 'Cf-Access-Jwt-Assertion': 'dummy-access-jwt' }.freeze

  def as_administrator(&)
    stub_cloudflare_access(staff_members(:administrator).email, &)
  end

  test 'an administrator lists staff members with their roles' do
    as_administrator { get '/admin/staff_members', headers: ACCESS_HEADERS }

    assert_response :ok

    res = JSON.parse(@response.body)

    assert_equal Admin::StaffMember.order(:email).pluck(:email), res.pluck('email')
    reader = res.find { |member| member['email'] == 'reader@example.com' }
    assert_equal [{ 'id' => roles(:reader).id, 'name' => 'reader' }], reader['roles']
    assert_nil reader['revoked_at']
    assert_not_nil res.find { |member| member['email'] == 'revoked@example.com' }['revoked_at']
  end

  test 'an administrator grants a role to a new email' do
    as_administrator do
      post '/admin/staff_members', params: { email: 'New@Example.com', role_id: roles(:moderator).id },
                                   headers: ACCESS_HEADERS
    end

    assert_response :created
    assert_equal 'new@example.com', JSON.parse(@response.body)['email']
    assert Admin::StaffMember.find_by(email: 'new@example.com').can?(Admin::Permission::DECIDE_REPORTS)
  end

  test 'granting to an email that is not an address answers unprocessable' do
    as_administrator do
      post '/admin/staff_members', params: { email: 'nobody', role_id: roles(:moderator).id },
                                   headers: ACCESS_HEADERS.merge('Accept-Language': 'ja')
    end

    assert_response :unprocessable_content
    assert_equal 'メールアドレスの形式が正しくありません。', JSON.parse(@response.body)['detail']
  end

  test 'granting an unknown role answers not found' do
    as_administrator do
      post '/admin/staff_members', params: { email: 'new@example.com', role_id: 0 }, headers: ACCESS_HEADERS
    end

    assert_response :not_found
    assert_not Admin::StaffMember.exists?(email: 'new@example.com')
  end

  test 'an administrator removes a role from another member' do
    as_administrator do
      delete "/admin/staff_members/#{staff_members(:reader).id}/roles/#{roles(:reader).id}", headers: ACCESS_HEADERS
    end

    assert_response :ok
    assert_empty JSON.parse(@response.body)['roles']
    assert_not Admin::StaffMember.find(staff_members(:reader).id).can?(Admin::Permission::READ_REPORTS)
  end

  test 'an administrator revokes another member' do
    as_administrator do
      post "/admin/staff_members/#{staff_members(:moderator).id}/revocation", headers: ACCESS_HEADERS
    end

    assert_response :created
    assert_not_nil JSON.parse(@response.body)['revoked_at']
    assert_not_includes Admin::StaffMember.active, staff_members(:moderator)
  end

  test 'an administrator cannot remove their own role or revoke themselves' do
    administrator = staff_members(:administrator)

    as_administrator do
      delete "/admin/staff_members/#{administrator.id}/roles/#{roles(:administrator).id}", headers: ACCESS_HEADERS
    end

    assert_response :unprocessable_content
    assert_equal I18n.t('messages.api.staff_member_self_change'), JSON.parse(@response.body)['detail']

    as_administrator { post "/admin/staff_members/#{administrator.id}/revocation", headers: ACCESS_HEADERS }

    assert_response :unprocessable_content
    assert administrator.reload.can?(Admin::Permission::MANAGE_STAFF)
    assert_includes Admin::StaffMember.active, administrator
  end

  test 'an administrator lists the roles with their permissions' do
    as_administrator { get '/admin/roles', headers: ACCESS_HEADERS }

    assert_response :ok

    administrator = JSON.parse(@response.body).find { |role| role['name'] == 'administrator' }
    assert_equal Admin::Permission::ALL.map(&:to_s).sort, administrator['permissions']
  end

  test 'a moderator without the permission to manage staff is forbidden' do
    stub_cloudflare_access(staff_members(:moderator).email) do
      get '/admin/staff_members', headers: ACCESS_HEADERS
      post '/admin/staff_members', params: { email: 'new@example.com', role_id: roles(:administrator).id },
                                   headers: ACCESS_HEADERS
    end

    assert_response :forbidden
    assert_not Admin::StaffMember.exists?(email: 'new@example.com')
  end
end
