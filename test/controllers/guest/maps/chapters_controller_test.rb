require 'test_helper'

class Guest::Maps::ChaptersControllerTest < ActionDispatch::IntegrationTest
  test 'index should return published chapters written from a public map' do
    get "/guest/maps/#{maps(:public_one).id}/chapters"

    assert_response :success

    res = JSON.parse(@response.body)
    ids = res.map { |chapter| chapter['id'] }

    assert_equal [chapters(:you_published_on_my_map).id, chapters(:my_published).id], ids
    assert_not_includes ids, chapters(:my_draft).id
    assert_not_includes ids, chapters(:you_draft_on_my_map).id
  end

  test 'index should not expose whether a chapter is editable' do
    get "/guest/maps/#{maps(:public_one).id}/chapters"

    assert_response :success

    res = JSON.parse(@response.body)

    assert res.none? { |chapter| chapter.key?('editable') }
  end

  test 'index on a private map should raise not found error' do
    get "/guest/maps/#{maps(:private).id}/chapters"

    assert_response :not_found
  end
end
