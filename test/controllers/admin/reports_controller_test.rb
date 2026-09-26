require 'test_helper'

class Admin::ReportsControllerTest < ActionDispatch::IntegrationTest
  MODERATOR_EMAIL = 'moderator@example.com'.freeze
  ACCESS_HEADERS = { 'Cf-Access-Jwt-Assertion': 'dummy-access-jwt' }.freeze

  setup do
    @report = Report.create!(moderatable: pins(:public_you_one), reporter: users(:me), category: 'spam')
  end

  test 'a moderator lists the pending reports oldest first' do
    travel 1.minute
    leaving = record_user('leaving')
    later = Report.create!(moderatable: comments(:two), reporter: leaving, category: 'hate')
    stub_identity_platform { leaving.destroy! }

    stub_cloudflare_access(MODERATOR_EMAIL) do
      get '/admin/reports', headers: ACCESS_HEADERS
    end

    assert_response :ok

    res = JSON.parse(@response.body)

    assert_equal [@report.id, later.id], res.pluck('id')
    assert_equal users(:me).name, res.first.dig('reporter', 'name')
    assert_nil res.second['reporter']
    assert_not res.first.key?('reporter_email')
  end

  test 'a decided report leaves the list' do
    @report.decide!(staff_member: staff_members(:moderator), outcome: 'kept', reason: 'Not spam.')

    stub_cloudflare_access(MODERATOR_EMAIL) do
      get '/admin/reports', headers: ACCESS_HEADERS
    end

    assert_response :ok
    assert_empty JSON.parse(@response.body)
  end

  test 'a moderator reads a report with its snapshot, history and sibling reports' do
    @report.decide!(staff_member: staff_members(:moderator), outcome: 'kept', reason: 'Not spam.')
    travel 1.minute
    sibling = Report.create!(moderatable: pins(:public_you_one), reporter: record_user('sibling'), category: 'hate')
    travel 1.minute
    current = Report.create!(moderatable: pins(:public_you_one), reporter: record_user('current'),
                             category: 'other', details: 'Offensive.')

    stub_cloudflare_access(MODERATOR_EMAIL) do
      get "/admin/reports/#{current.id}", headers: ACCESS_HEADERS
    end

    assert_response :ok

    res = JSON.parse(@response.body)

    assert_equal 'pending', res['status']
    assert_equal 'Offensive.', res['details']
    assert_includes res['content_snapshot'], pins(:public_you_one).comment
    assert res['target_available']
    assert_nil res['moderatable_parent']
    assert_not res['edited_since_filed']
    assert_equal ['kept'], res['decisions'].pluck('outcome')
    assert_equal [MODERATOR_EMAIL], res['decisions'].pluck('moderator_email')
    assert_equal [sibling.id], res['other_pending_reports'].pluck('id')
  end

  test 'a reported comment carries the content it was posted on' do
    report = Report.create!(moderatable: comments(:on_my_published_chapter), reporter: users(:me),
                            category: 'spam')

    stub_cloudflare_access(MODERATOR_EMAIL) do
      get "/admin/reports/#{report.id}", headers: ACCESS_HEADERS
    end

    assert_response :ok
    assert_equal({ 'type' => 'Chapter', 'id' => chapters(:my_published).id },
                 JSON.parse(@response.body)['moderatable_parent'])
  end

  test 'a reported journal carries the user it belongs to' do
    report = Report.create!(moderatable: journals(:you_journal), reporter: users(:me), category: 'spam')

    stub_cloudflare_access(MODERATOR_EMAIL) do
      get "/admin/reports/#{report.id}", headers: ACCESS_HEADERS
    end

    assert_response :ok
    assert_equal({ 'type' => 'User', 'id' => users(:you).id }, JSON.parse(@response.body)['moderatable_parent'])
  end

  test 'an assertion Cloudflare Access rejects is answered unauthorized' do
    stub_cloudflare_access(nil) do
      get '/admin/reports', headers: ACCESS_HEADERS
    end

    assert_response :unauthorized
  end

  test 'a signed-in Qoodish user without an Access assertion is answered unauthorized' do
    stub_google_auth(users(:me)) do
      get "/admin/reports/#{@report.id}", headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :unauthorized
  end

  test 'without any credentials the endpoint answers unauthorized' do
    get '/admin/reports'

    assert_response :unauthorized
  end
end
