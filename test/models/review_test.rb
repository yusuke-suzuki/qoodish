require 'test_helper'

class ReviewTest < ActiveSupport::TestCase
  test 'image_variants returns the first image variants hash' do
    review = reviews(:public_one)
    expected = review.images.first.variants

    assert_equal expected, review.image_variants
  end

  test 'image_variants returns nil when the review has no images' do
    review = reviews(:public_two)
    assert_empty review.images

    assert_nil review.image_variants
  end

  test 'name and comment drop carriage returns on assignment' do
    review = maps(:public_one).reviews.create!(
      user: users(:me),
      name: "Cafe\r\nBonjour",
      comment: "Nice\r\nplace",
      latitude: 35.681382,
      longitude: 139.766084
    )

    assert_equal "Cafe\nBonjour", review.reload.name
    assert_equal "Nice\nplace", review.comment
  end
end
