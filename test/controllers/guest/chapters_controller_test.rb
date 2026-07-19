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

  test 'show a published chapter returns the content verbatim' do
    get "/guest/chapters/#{chapters(:my_published).id}"

    assert_response :success

    res = JSON.parse(@response.body)

    assert_equal chapters(:my_published).id, res['id']
    assert_not res.key?('editable')
    assert_equal chapters(:my_published).content['root'], res['content']['root']
    assert_equal users(:me).biography, res['author']['biography']
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
