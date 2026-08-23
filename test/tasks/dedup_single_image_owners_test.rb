require 'test_helper'

class DedupSingleImageOwnersTest < ActiveSupport::TestCase
  TASK = Rails.root.join('lib/tasks/dedup_single_image_owners.rb').to_s

  test 'keeps the oldest image of a map and drops the later ones' do
    kept, *dropped = Array.new(3) { |i| attach_image(maps(:public_one), "map-#{i}") }

    stub_cloudflare_images { load TASK }

    assert_equal [kept.id], maps(:public_one).reload.image_ids
    dropped.each { |image| assert_not Image.exists?(image.id) }
  end

  test 'keeps the oldest image of a user and drops the later ones' do
    kept, dropped = Array.new(2) { |i| attach_image(users(:me), "user-#{i}") }

    stub_cloudflare_images { load TASK }

    assert_equal [kept.id], users(:me).reload.image_ids
    assert_not Image.exists?(dropped.id)
  end

  test 'leaves an owner holding a single image untouched' do
    image = attach_image(maps(:public_two), 'single')

    stub_cloudflare_images { load TASK }

    assert_equal [image.id], maps(:public_two).reload.image_ids
  end

  test 'leaves owners allowed to hold several images untouched' do
    review = reviews(:public_one)

    assert_equal 2, review.images.count

    stub_cloudflare_images { load TASK }

    assert_equal 2, review.reload.images.count
  end

  test 'a second run drops nothing more' do
    attach_image(maps(:public_one), 'first')
    attach_image(maps(:public_one), 'second')

    stub_cloudflare_images { load TASK }

    assert_no_difference 'Image.count' do
      stub_cloudflare_images { load TASK }
    end
  end

  private

  def attach_image(imageable, suffix)
    users(:me).owned_images.create!(
      imageable: imageable,
      url: "https://imagedelivery.net/mockhash/dedup-#{suffix}/public"
    )
  end
end
