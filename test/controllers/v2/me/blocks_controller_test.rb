require 'test_helper'

class V2::Me::BlocksControllerTest < ActionDispatch::IntegrationTest
  test 'index pages through the accounts with the cursor it hands out' do
    accounts = Array.new(Block::PER_PAGE + 1) { |i| record_user("blocks-#{i}") }
    accounts.each { |user| users(:me).block!(user) }

    pages = stub_google_auth(users(:me)) { page_through('/v2/me/blocks', headers: { 'Authorization': 'Bearer dummytoken' }) }

    assert_equal [Block::PER_PAGE, 1], pages.map(&:size)
    assert_equal accounts.reverse.map(&:id), pages.flatten
  end

  test 'index without a token should be unauthorized' do
    get '/v2/me/blocks'

    assert_response :unauthorized
  end
end
