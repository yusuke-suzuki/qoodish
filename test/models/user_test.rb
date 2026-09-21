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

  test 'record! writes the first revision and points the account at it' do
    user = User.record!(uid: 'record-uid', name: 'Recorded')

    assert_equal 1, user.revisions.count
    assert_equal user.revisions.last, user.current_revision
    assert_equal 'Recorded', user.current_revision.name
  end

  test 'revise! appends a revision and leaves the previous one untouched' do
    user = users(:me)
    previous = user.current_revision

    user.revise!(user: user, name: 'Renamed', biography: 'Rewritten')

    assert_equal 'Renamed', user.reload.name
    assert_equal 2, user.revisions.count
    assert_equal user.revisions.last, user.current_revision
    assert_equal 'watame', previous.reload.name
    assert_equal 'This is a biography', previous.biography
  end

  test 'the log keeps a biography that was cleared' do
    user = users(:me)

    user.revise!(user: user, biography: '')

    assert_equal '', user.reload.biography
    assert_equal 'This is a biography', user.revisions.first.biography
  end

  test 'revising with what the account already says appends nothing' do
    user = users(:me)

    assert_no_difference -> { user.revisions.count } do
      user.revise!(user: user, name: user.name, biography: user.biography)
      user.revise!(user: user)
    end
  end

  test 'changing the avatar alone appends nothing' do
    user = users(:me)

    assert_no_difference -> { user.revisions.count } do
      user.revise!(user: user, image_id: images(:one).id)
    end

    assert_equal images(:one), user.reload.image
  end

  test 'a revision cannot be rewritten' do
    revision = users(:me).current_revision

    assert_raises(ActiveRecord::ReadonlyAttributeError) { revision.update!(name: 'rewritten') }
  end

  test 'the name cannot be changed outside a revision' do
    user = users(:me)

    assert_raises(ActiveRecord::ReadOnlyRecord) { user.update!(name: 'Renamed') }
    assert_equal 'watame', user.reload.name
  end

  test 'an account cannot be created outside a revision' do
    assert_raises(ActiveRecord::ReadOnlyRecord) do
      User.create!(uid: 'sneaked-in-uid', name: 'Sneaked in')
    end
  end

  test 'an account is not handed discard!' do
    assert_not_respond_to users(:me), :discard!
  end

  test 'erasing an account destroys the revisions it wrote' do
    assert_difference 'UserRevision.count', -1 do
      stub_identity_platform { users(:you).destroy! }
    end
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
