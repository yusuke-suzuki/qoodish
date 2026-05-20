require 'test_helper'

class CommentTest < ActiveSupport::TestCase
  test 'image_variants delegates to commentable' do
    comment = comments(:one)
    assert_equal comment.commentable.image_variants, comment.image_variants
  end
end
