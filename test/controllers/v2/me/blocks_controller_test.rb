require 'test_helper'

class V2::Me::BlocksControllerTest < ActionDispatch::IntegrationTest
  test 'index pages through the accounts with the cursor it hands out' do
    accounts = Array.new(Block::PER_PAGE + 1) { |i| record_user("blocks-#{i}") }
    accounts.each { |user| users(:me).block!(user) }

    pages = stub_google_auth(users(:me)) { page_through('/v2/me/blocks', headers: { 'Authorization': 'Bearer dummytoken' }) }

    assert_equal [Block::PER_PAGE, 1], pages.map(&:size)
    assert_equal accounts.reverse.map(&:id), pages.flatten
  end

  test 'index lists an account once even if it was blocked twice at once' do
    Block.create!(blocker: users(:me), blocked: users(:you))
    Block.new(blocker: users(:me), blocked: users(:you)).save!(validate: false)

    stub_google_auth(users(:me)) do
      get '/v2/me/blocks', headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success
    assert_equal [users(:you).id], JSON.parse(@response.body)['data'].pluck('id')
  end

  test 'index does not list the accounts that blocked you' do
    users(:you).block!(users(:me))

    stub_google_auth(users(:me)) do
      get '/v2/me/blocks', headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success
    assert_empty JSON.parse(@response.body)['data']
  end

  test 'index without a token should be unauthorized' do
    get '/v2/me/blocks'

    assert_response :unauthorized
  end
end
