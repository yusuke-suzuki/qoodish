require 'test_helper'

class Admin::Reports::DecisionsControllerTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  MODERATOR_EMAIL = 'moderator@example.com'.freeze
  ACCESS_HEADERS = { 'Cf-Access-Jwt-Assertion': 'dummy-access-jwt' }.freeze

  setup do
    @pin = pins(:public_you_one)
    @report = Report.create!(moderatable: @pin, reporter: users(:me), category: 'hate')
  end

  test 'a moderator removes the content and is recorded by their Access email' do
    assert_enqueued_emails 2 do
      stub_cloudflare_access(MODERATOR_EMAIL) do
        post "/admin/reports/#{@report.id}/decision",
             params: { outcome: 'removed', reason: 'Hate speech.' },
             headers: ACCESS_HEADERS
      end
    end

    assert_response :created

    res = JSON.parse(@response.body)
    decision = ModerationDecision.find(res['id'])

    assert decision.removed?
    assert_equal staff_members(:moderator), decision.staff_member
    assert_equal MODERATOR_EMAIL, decision.staff_member.email
    assert_equal MODERATOR_EMAIL, res['moderator_email']
    assert_not_includes Pin.public_open, @pin
    assert_equal 'removed', @report.status
  end

  test 'a moderator keeps the content' do
    stub_cloudflare_access(MODERATOR_EMAIL) do
      post "/admin/reports/#{@report.id}/decision",
           params: { outcome: 'kept', reason: 'Not hate speech.' },
           headers: ACCESS_HEADERS
    end

    assert_response :created
    assert_equal 'kept', @report.status
    assert_includes Pin.public_open, @pin
  end

  test 'a moderator closes a report whose target is gone' do
    stub_identity_platform { users(:you).destroy! }

    stub_cloudflare_access(MODERATOR_EMAIL) do
      post "/admin/reports/#{@report.id}/decision",
           params: { outcome: 'unavailable', reason: 'The author deleted the account.' },
           headers: ACCESS_HEADERS
    end

    assert_response :created
    assert_equal 'unavailable', @report.reload.status
  end

  test 'a decision the content does not allow answers unprocessable' do
    report = Report.create!(moderatable: users(:you), reporter: users(:me), category: 'impersonation')

    stub_cloudflare_access(MODERATOR_EMAIL) do
      post "/admin/reports/#{report.id}/decision",
           params: { outcome: 'removed', reason: 'Impersonation.' },
           headers: ACCESS_HEADERS
    end

    assert_response :unprocessable_content
    assert_includes JSON.parse(@response.body)['detail'],
                    'Target type is an account or a journal, which cannot be removed. Choose "Keep the content" instead.'
    assert_empty ModerationDecision.all
  end

  test 'an unknown outcome answers unprocessable' do
    stub_cloudflare_access(MODERATOR_EMAIL) do
      post "/admin/reports/#{@report.id}/decision",
           params: { outcome: 'deleted', reason: 'x' },
           headers: ACCESS_HEADERS
    end

    assert_response :unprocessable_content
    assert_empty ModerationDecision.all
  end

  test 'a decision without a reason answers unprocessable with the reason to fill in' do
    stub_cloudflare_access(MODERATOR_EMAIL) do
      post "/admin/reports/#{@report.id}/decision",
           params: { outcome: 'kept' },
           headers: ACCESS_HEADERS.merge('Accept-Language': 'ja')
    end

    assert_response :unprocessable_content
    assert_includes JSON.parse(@response.body)['detail'], '理由を入力してください。'
    assert_empty ModerationDecision.all
  end

  test 'a decision without an outcome answers unprocessable' do
    stub_cloudflare_access(MODERATOR_EMAIL) do
      post "/admin/reports/#{@report.id}/decision",
           params: { reason: 'Fine.' },
           headers: ACCESS_HEADERS
    end

    assert_response :unprocessable_content
    assert_empty ModerationDecision.all
  end

  test 'a reason that is not a string is not permitted' do
    stub_cloudflare_access(MODERATOR_EMAIL) do
      post "/admin/reports/#{@report.id}/decision",
           params: { outcome: 'kept', reason: { text: 'Fine.' } },
           headers: ACCESS_HEADERS
    end

    assert_response :unprocessable_content
    assert_empty ModerationDecision.all
  end

  test 'a staff member without the permission to decide is forbidden' do
    stub_cloudflare_access(staff_members(:reader).email) do
      post "/admin/reports/#{@report.id}/decision",
           params: { outcome: 'kept', reason: 'Fine.' },
           headers: ACCESS_HEADERS
    end

    assert_response :forbidden
    assert_empty ModerationDecision.all
  end

  test 'an Access user who is not staff is forbidden' do
    stub_cloudflare_access('stranger@example.com') do
      post "/admin/reports/#{@report.id}/decision",
           params: { outcome: 'kept', reason: 'Fine.' },
           headers: ACCESS_HEADERS
    end

    assert_response :forbidden
    assert_empty ModerationDecision.all
  end

  test 'a revoked staff member is forbidden' do
    stub_cloudflare_access(staff_members(:revoked).email) do
      post "/admin/reports/#{@report.id}/decision",
           params: { outcome: 'kept', reason: 'Fine.' },
           headers: ACCESS_HEADERS
    end

    assert_response :forbidden
    assert_empty ModerationDecision.all
  end

  test 'a signed-in Qoodish user without an Access assertion cannot decide' do
    stub_google_auth(users(:me)) do
      post "/admin/reports/#{@report.id}/decision",
           params: { outcome: 'removed', reason: 'Hate speech.' },
           headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :unauthorized
    assert_empty ModerationDecision.all
  end
end
