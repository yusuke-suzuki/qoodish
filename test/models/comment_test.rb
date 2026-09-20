require 'test_helper'

class CommentTest < ActiveSupport::TestCase
  test 'image_variants delegates to commentable' do
    comment = comments(:one)
    assert_equal comment.commentable.image_variants, comment.image_variants
  end

  test 'body drops carriage returns on assignment' do
    comment = pins(:public_one).comments.create!(
      user: users(:me),
      body: "First\r\nline"
    )

    assert_equal "First\nline", comment.reload.body
  end

  test 'discard! keeps the row and takes it off the pin' do
    comment = comments(:one)

    assert_no_difference 'Comment.count' do
      comment.discard!
    end

    assert_predicate comment.reload, :deleted?
    assert_not_includes pins(:public_one).comments.reload, comment
    assert_not_includes users(:me).comments.reload, comment
  end

  test 'destroying the pin destroys the comments it discarded' do
    comments(:one).discard!

    assert_difference 'Comment.count', -2 do
      pins(:public_one).destroy!
    end
  end

  test 'erasing an account destroys the comments it discarded' do
    comments(:two).discard!

    assert_difference 'Comment.count', -1 do
      stub_identity_platform { users(:you).destroy! }
    end
  end
end
