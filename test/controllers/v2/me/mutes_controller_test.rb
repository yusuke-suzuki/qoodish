require 'test_helper'

class V2::Me::MutesControllerTest < ActionDispatch::IntegrationTest
  test 'index pages through the accounts with the cursor it hands out' do
    accounts = Array.new(Mute::PER_PAGE + 1) { |i| record_user("mutes-#{i}") }
    accounts.each { |user| users(:me).mute!(user) }

    pages = stub_google_auth(users(:me)) { page_through('/v2/me/mutes', headers: { 'Authorization': 'Bearer dummytoken' }) }

    assert_equal [Mute::PER_PAGE, 1], pages.map(&:size)
    assert_equal accounts.reverse.map(&:id), pages.flatten
  end

  test 'index without a token should be unauthorized' do
    get '/v2/me/mutes'

    assert_response :unauthorized
  end
end
