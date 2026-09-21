require 'test_helper'

class Me::ChaptersControllerTest < ActionDispatch::IntegrationTest
  test 'index should return own chapters in both statuses' do
    stub_google_auth(users(:me)) do
      get '/me/chapters',
          headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert_equal [chapters(:my_draft).id, chapters(:my_published).id].sort,
                 res.map { |chapter| chapter['id'] }.sort
  end

  test 'show own draft chapter should be success' do
    stub_google_auth(users(:me)) do
      get "/me/chapters/#{chapters(:my_draft).id}",
          headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert_equal chapters(:my_draft).id, res['id']
    assert res['editable']
  end

  test 'show a chapter of another user should raise not found error' do
    stub_google_auth(users(:me)) do
      get "/me/chapters/#{chapters(:you_published).id}",
          headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :not_found
  end

  test 'update title and content should be success' do
    stub_google_auth(users(:me)) do
      put "/me/chapters/#{chapters(:my_draft).id}",
          params: {
            title: 'Renamed chapter',
            content: { root: { type: 'root', version: 1, children: [] } }
          },
          headers: { 'Authorization': 'Bearer dummytoken' },
          as: :json
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert_equal 'Renamed chapter', res['title']
    assert_empty res['content']['root']['children']
  end

  test 'show counts the comments left on the chapter' do
    stub_google_auth(users(:me)) do
      get "/me/chapters/#{chapters(:my_published).id}",
          headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_equal 1, JSON.parse(@response.body)['comments_count']
  end

  test 'publish a draft chapter should be success' do
    stub_google_auth(users(:me)) do
      put "/me/chapters/#{chapters(:my_draft).id}",
          params: { status: 'published' },
          headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert_equal 'published', res['status']
  end

  test 'revert a published chapter to draft should be success' do
    stub_google_auth(users(:me)) do
      put "/me/chapters/#{chapters(:my_published).id}",
          params: { status: 'draft' },
          headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert_equal 'draft', res['status']
  end

  test 'update with an unknown status should raise unprocessable error' do
    stub_google_auth(users(:me)) do
      put "/me/chapters/#{chapters(:my_draft).id}",
          params: { status: 'archived' },
          headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :unprocessable_content
  end

  test 'update with an invalid content should raise unprocessable error' do
    stub_google_auth(users(:me)) do
      put "/me/chapters/#{chapters(:my_draft).id}",
          params: { content: { foo: 'bar' } },
          headers: { 'Authorization': 'Bearer dummytoken' },
          as: :json
    end

    assert_response :unprocessable_content
  end

  test 'update a chapter of another user should raise not found error' do
    stub_google_auth(users(:me)) do
      put "/me/chapters/#{chapters(:you_draft).id}",
          params: { title: 'Hijacked' },
          headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :not_found
  end

  test 'destroy own chapter should be success' do
    chapter = chapters(:my_draft)

    assert_no_difference 'Chapter.count' do
      stub_google_auth(users(:me)) do
        delete "/me/chapters/#{chapter.id}",
               headers: { 'Authorization': 'Bearer dummytoken' }
      end
    end

    assert_response :success
    assert_predicate chapter.reload, :deleted?
    assert_not_includes Chapter.readable_by(users(:me)), chapter
  end

  test 'destroy a chapter of another user should raise not found error' do
    stub_google_auth(users(:me)) do
      delete "/me/chapters/#{chapters(:you_draft).id}",
             headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :not_found
  end
end
