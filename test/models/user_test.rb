require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test 'map_author? is true only for own maps' do
    assert users(:me).map_author?(maps(:public_one))
    assert_not users(:me).map_author?(maps(:public_unfollowing))
  end

  test 'editable? is true for author and coauthor' do
    assert users(:me).editable?(maps(:public_one))        # author
    assert users(:me).editable?(maps(:private_following)) # coauthor
    assert_not users(:me).editable?(maps(:public_unfollowing))
  end

  test 'bookmarkable? is true only for public maps the user is not involved with' do
    assert users(:me).bookmarkable?(maps(:public_unfollowing))      # public, not involved
    assert_not users(:me).bookmarkable?(maps(:public_one))          # author
    assert_not users(:me).bookmarkable?(maps(:private_unfollowing)) # private
    assert_not users(:me).bookmarkable?(maps(:private_following))   # coauthor
  end

  test 'the avatar is one of the images the user uploaded' do
    user = users(:me)

    user.update!(image: images(:one))

    assert_equal images(:one).url, user.reload.image_url
    assert_equal images(:one).variants, user.image_variants
  end

  test 'an image another user uploaded cannot become the avatar' do
    foreign_image = users(:you).owned_images.create!(
      url: 'https://imagedelivery.net/mockhash/avatar-foreign/public'
    )

    assert_not users(:me).update(image: foreign_image)
  end

  test 'a user without an avatar serves an empty url' do
    assert_empty users(:you).image_url
    assert_nil users(:you).image_variants
  end

  test 'changing the avatar leaves the previous image with its owner' do
    user = users(:me)
    user.update!(image: images(:one))

    user.update!(image: images(:two))

    assert_equal images(:two), user.reload.image
    assert_includes user.owned_images, images(:one)
  end

  test 'destroying the image an avatar points at releases the pointer' do
    user = users(:me)
    user.update!(image: images(:one))

    stub_cloudflare_images { images(:one).destroy! }

    assert_nil user.reload.image_id
  end

  test 'erasing an account takes the avatar with it' do
    user = users(:you)
    avatar = user.owned_images.create!(
      url: 'https://imagedelivery.net/mockhash/avatar-erased/public'
    )
    user.update!(image: avatar)

    stub_identity_platform do
      stub_cloudflare_images { user.destroy! }
    end

    assert_not Image.exists?(avatar.id)
  end
end
