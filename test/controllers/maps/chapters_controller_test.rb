require 'test_helper'

class Maps::ChaptersControllerTest < ActionDispatch::IntegrationTest
  LEXICAL_DOCUMENT = {
    root: {
      type: 'root',
      version: 1,
      children: []
    }
  }.freeze

  test 'create a chapter recording a journey should be success' do
    assert_difference 'Chapter.count', 1 do
      stub_google_auth(users(:me)) do
        post "/maps/#{maps(:private).id}/chapters",
             params: {
               journey_id: journeys(:my_in_progress).id,
               title: 'A walk',
               content: LEXICAL_DOCUMENT
             },
             headers: { 'Authorization': 'Bearer dummytoken' },
             as: :json
      end
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert_equal journeys(:my_in_progress).id, res['journey_id']
    assert_equal 'draft', res['status']
    assert res['editable']
  end

  test 'create a chapter without a journey should be success' do
    assert_difference 'Chapter.count', 1 do
      stub_google_auth(users(:you)) do
        post "/maps/#{maps(:public_one).id}/chapters",
             params: { title: 'A walk', content: LEXICAL_DOCUMENT },
             headers: { 'Authorization': 'Bearer dummytoken' },
             as: :json
      end
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert_nil res['journey_id']
  end

  test 'create a chapter with a journey of another user should raise not found error' do
    stub_google_auth(users(:you)) do
      post "/maps/#{maps(:public_one).id}/chapters",
           params: {
             journey_id: journeys(:my_finished).id,
             title: 'A walk',
             content: LEXICAL_DOCUMENT
           },
           headers: { 'Authorization': 'Bearer dummytoken' },
           as: :json
    end

    assert_response :not_found
  end

  test 'create a chapter with a journey on another map should raise unprocessable error' do
    stub_google_auth(users(:me)) do
      post "/maps/#{maps(:public_one).id}/chapters",
           params: {
             journey_id: journeys(:my_in_progress).id,
             title: 'A walk',
             content: LEXICAL_DOCUMENT
           },
           headers: { 'Authorization': 'Bearer dummytoken' },
           as: :json
    end

    assert_response :unprocessable_content
  end

  test 'create a chapter should serialize the journal of the author' do
    stub_google_auth(users(:me)) do
      post "/maps/#{maps(:public_one).id}/chapters",
           params: { title: 'A walk', content: LEXICAL_DOCUMENT },
           headers: { 'Authorization': 'Bearer dummytoken' },
           as: :json
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert_equal journals(:my_journal).id, res['journal']['id']
  end

  test 'create a chapter on an unreferenceable private map should raise not found error' do
    stub_google_auth(users(:me)) do
      post "/maps/#{maps(:private_unfollowing).id}/chapters",
           params: { title: 'A walk', content: LEXICAL_DOCUMENT },
           headers: { 'Authorization': 'Bearer dummytoken' },
           as: :json
    end

    assert_response :not_found
  end
end
