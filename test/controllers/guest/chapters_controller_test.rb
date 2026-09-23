require 'test_helper'

class Guest::ChaptersControllerTest < ActionDispatch::IntegrationTest
  test 'index should return latest published chapters on public maps' do
    get '/guest/chapters'

    assert_response :success

    res = JSON.parse(@response.body)
    ids = res.map { |chapter| chapter['id'] }

    assert_includes ids, chapters(:my_published).id
    assert_includes ids, chapters(:you_published).id
    assert_not_includes ids, chapters(:you_private_published_following).id
    assert_not_includes ids, chapters(:my_draft).id
  end

  test 'index should page with next_timestamp' do
    newest = chapters(:you_published_on_my_map)

    get '/guest/chapters', params: { next_timestamp: newest.created_at.iso8601 }

    assert_response :success

    res = JSON.parse(@response.body)
    ids = res.map { |chapter| chapter['id'] }

    assert_not_includes ids, newest.id
    assert_includes ids, chapters(:my_published).id
    assert(res.all? { |chapter| Time.parse(chapter['created_at']) < newest.created_at })
  end

  test 'index should reject a malformed cursor' do
    get '/guest/chapters', params: { next_timestamp: 'not-a-time' }

    assert_response :bad_request
  end

  test 'show a published chapter returns the content verbatim' do
    get "/guest/chapters/#{chapters(:my_published).id}"

    assert_response :success

    res = JSON.parse(@response.body)

    assert_equal chapters(:my_published).id, res['id']
    assert_not res.key?('editable')
    assert_equal chapters(:my_published).content['root'], res['content']['root']
    assert_equal users(:me).biography, res['author']['biography']
  end

  test 'show tells a guest how many likes the chapter holds' do
    users(:you).liked!(chapters(:my_published))

    get "/guest/chapters/#{chapters(:my_published).id}"

    assert_equal 1, JSON.parse(@response.body)['likes_count']
  end

  test 'show does not tell a guest whether the chapter was liked' do
    users(:you).liked!(chapters(:my_published))

    get "/guest/chapters/#{chapters(:my_published).id}"

    assert_not_includes JSON.parse(@response.body).keys, 'liked'
  end

  test 'show counts the comments left on the chapter' do
    get "/guest/chapters/#{chapters(:my_published).id}"

    assert_equal 1, JSON.parse(@response.body)['comments_count']
  end

  test 'show a draft chapter should raise not found error' do
    get "/guest/chapters/#{chapters(:my_draft).id}"

    assert_response :not_found
  end

  test 'show a published chapter on a private map should raise not found error' do
    get "/guest/chapters/#{chapters(:you_private_published_unfollowing).id}"

    assert_response :not_found
  end
end
