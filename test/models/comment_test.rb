require 'test_helper'

class CommentTest < ActiveSupport::TestCase
  test 'image_variants delegates to commentable' do
    comment = comments(:one)
    assert_equal comment.commentable.image_variants, comment.image_variants
  end

  test 'body drops carriage returns on assignment' do
    comment = reviews(:public_one).comments.create!(
      user: users(:me),
      body: "First\r\nline"
    )

    assert_equal "First\nline", comment.reload.body
  end
end
