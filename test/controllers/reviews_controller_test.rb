require 'test_helper'

class ReviewsControllerTest < ActionDispatch::IntegrationTest
  test 'get feeds should be success' do
    stub_google_auth(users(:me)) do
      get '/reviews', headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert_not res.empty?
    assert_not(res.any? do |review|
                 review['map']['id'] == maps(:private_unfollowing).id || review['map']['id'] == maps(:public_unfollowing).id
               end)
  end
end
