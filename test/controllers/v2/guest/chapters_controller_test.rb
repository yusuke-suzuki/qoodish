require 'test_helper'

class V2::Guest::ChaptersControllerTest < ActionDispatch::IntegrationTest
  test 'index pages through the feed with the cursor it hands out' do
    publish_chapters(CHAPTER_FEED_PER_PAGE)

    pages = page_through('/guest/v2/chapters')

    assert_operator pages.size, :>, 1
    assert_equal Chapter.public_open.order(created_at: :desc, id: :desc).ids, pages.flatten
  end

  test 'index rejects a cursor it did not hand out' do
    get '/guest/v2/chapters', params: { cursor: 'not-a-cursor' }

    assert_response :bad_request
  end
end
