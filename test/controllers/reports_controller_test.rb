require 'test_helper'

class ReportsControllerTest < ActionDispatch::IntegrationTest
  test 'a signed-in user reports a pin' do
    stub_google_auth(users(:me)) do
      post '/reports',
           params: {
             moderatable_type: 'Pin',
             moderatable_id: pins(:public_you_one).id,
             category: 'harassment',
             details: 'Targets me by name.'
           },
           headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :created

    res = JSON.parse(@response.body)
    report = Report.find(res['id'])

    assert_equal 'harassment', res['category']
    assert_equal 'pending', res['status']
    assert_equal users(:me), report.reporter
    assert_equal pins(:public_you_one), report.moderatable
    assert_equal 'Targets me by name.', report.details
  end

  test 'a signed-in user reports a comment, a map, a chapter, a journal and a user' do
    targets = {
      'Comment' => comments(:two).id,
      'Map' => maps(:public_unfollowing).id,
      'Chapter' => chapters(:you_published).id,
      'Journal' => journals(:you_journal).id,
      'User' => users(:you).id
    }

    targets.each do |type, id|
      stub_google_auth(users(:me)) do
        post '/reports',
             params: { moderatable_type: type, moderatable_id: id, category: 'spam' },
             headers: { 'Authorization': 'Bearer dummytoken' }
      end

      assert_response :created, "#{type} should be reportable"
    end
  end

  test 'the report records the locale of the request' do
    stub_google_auth(users(:me)) do
      post '/reports',
           params: { moderatable_type: 'Pin', moderatable_id: pins(:public_you_one).id, category: 'spam' },
           headers: { 'Authorization': 'Bearer dummytoken', 'Accept-Language': 'ja' }
    end

    assert_response :created
    assert_equal 'ja', Report.last.locale
  end

  test 'content the user cannot reference answers not found' do
    stub_google_auth(users(:me)) do
      post '/reports',
           params: { moderatable_type: 'Pin', moderatable_id: pins(:private_unfollowing_you).id,
                     category: 'spam' },
           headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :not_found
    assert_empty Report.all
  end

  test 'an unsupported type answers bad request' do
    stub_google_auth(users(:me)) do
      post '/reports',
           params: { moderatable_type: 'Vote', moderatable_id: votes(:public_one).id, category: 'spam' },
           headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :bad_request
  end

  test 'a second report while the first waits for a decision answers unprocessable' do
    Report.create!(moderatable: pins(:public_you_one), reporter: users(:me), category: 'spam')

    stub_google_auth(users(:me)) do
      post '/reports',
           params: { moderatable_type: 'Pin', moderatable_id: pins(:public_you_one).id, category: 'hate' },
           headers: { 'Authorization': 'Bearer dummytoken', 'Accept-Language': 'ja' }
    end

    assert_response :unprocessable_content
    assert_equal '対象は報告済みで、現在確認中です。', JSON.parse(@response.body)['detail']
    assert_equal 1, Report.count
  end

  test 'a second report after the first was decided is filed' do
    first = Report.create!(moderatable: pins(:public_you_one), reporter: users(:me), category: 'spam')
    first.decide!(staff_member: staff_members(:moderator), outcome: 'kept', reason: 'Not spam.')
    travel 1.minute

    stub_google_auth(users(:me)) do
      post '/reports',
           params: { moderatable_type: 'Pin', moderatable_id: pins(:public_you_one).id, category: 'hate' },
           headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :created
    assert_equal 2, Report.count
  end

  test 'reporting your own pin answers unprocessable' do
    stub_google_auth(users(:me)) do
      post '/reports',
           params: { moderatable_type: 'Pin', moderatable_id: pins(:public_one).id, category: 'spam' },
           headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :unprocessable_content
  end

  test 'an email in the payload does not change who filed the report' do
    stub_google_auth(users(:me)) do
      post '/reports',
           params: {
             moderatable_type: 'Pin',
             moderatable_id: pins(:public_you_one).id,
             category: 'spam',
             reporter_email: 'other@example.com'
           },
           headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :created
    assert_equal users(:me), Report.last.reporter
  end

  test 'without authentication the endpoint answers unauthorized' do
    post '/reports',
         params: { moderatable_type: 'Pin', moderatable_id: pins(:public_you_one).id, category: 'spam' }

    assert_response :unauthorized
  end
end
