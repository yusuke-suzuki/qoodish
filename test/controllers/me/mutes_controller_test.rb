require 'test_helper'

class Me::MutesControllerTest < ActionDispatch::IntegrationTest
  test 'index lists the muted accounts' do
    users(:me).mute!(users(:you))

    stub_google_auth(users(:me)) do
      get '/me/mutes', headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success
    assert_equal [users(:you).id], JSON.parse(@response.body).pluck('id')
  end

  test 'index continues after the cursor it was given' do
    muted = Array.new(3) { |i| record_user("muted-#{i}") }
    muted.each { |user| users(:me).mute!(user) }
    cursor = users(:me).mutes.find_by!(muted: muted.last).id

    stub_google_auth(users(:me)) do
      get '/me/mutes', params: { next_id: cursor }, headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success
    assert_equal muted.first(2).reverse.map(&:id), JSON.parse(@response.body).pluck('id')
  end
end
