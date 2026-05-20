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
end
