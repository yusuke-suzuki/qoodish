require 'test_helper'

class Me::BlocksControllerTest < ActionDispatch::IntegrationTest
  test 'index lists the blocked accounts' do
    users(:me).block!(users(:you))

    stub_google_auth(users(:me)) do
      get '/me/blocks', headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success
    assert_equal [users(:you).id], JSON.parse(@response.body).pluck('id')
  end

  test 'index lists an account once even if it was blocked twice at once' do
    Block.create!(blocker: users(:me), blocked: users(:you))
    Block.new(blocker: users(:me), blocked: users(:you)).save!(validate: false)

    stub_google_auth(users(:me)) do
      get '/me/blocks', headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success
    assert_equal [users(:you).id], JSON.parse(@response.body).pluck('id')
  end

  test 'index pages through the blocked accounts newest first' do
    blocked = Array.new(Block::PER_PAGE + 1) { |i| record_user("blocked-#{i}") }
    blocked.each { |user| users(:me).block!(user) }

    pages = []
    next_id = nil
    stub_google_auth(users(:me)) do
      3.times do
        get '/me/blocks', params: { next_id: next_id }.compact, headers: { 'Authorization': 'Bearer dummytoken' }
        pages << JSON.parse(@response.body)
        next_id = pages.last.last&.fetch('cursor')
      end
    end

    assert_equal [Block::PER_PAGE, 1, 0], pages.map(&:size)
    assert_equal blocked.reverse.map(&:id), pages.flatten.pluck('id')
  end

  test 'index does not list the accounts that blocked you' do
    users(:you).block!(users(:me))

    stub_google_auth(users(:me)) do
      get '/me/blocks', headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success
    assert_empty JSON.parse(@response.body)
  end
end
