require 'test_helper'

class BackfillUserImagesTest < ActiveSupport::TestCase
  TASK = Rails.root.join('lib/tasks/backfill_user_images.rb').to_s

  test 'points a user at the image the legacy imageable column holds' do
    image = attach_legacy_image(users(:me), 'first')

    run_task

    assert_equal image, users(:me).reload.image
  end

  test 'keeps the oldest of several legacy images' do
    kept = attach_legacy_image(users(:me), 'kept')
    attach_legacy_image(users(:me), 'later')

    run_task

    assert_equal kept, users(:me).reload.image
  end

  test 'leaves a user without a legacy image alone' do
    run_task

    assert_nil users(:you).reload.image_id
  end

  test 'a second run changes nothing' do
    attach_legacy_image(users(:me), 'first')

    run_task

    assert_no_changes -> { users(:me).reload.image_id } do
      run_task
    end
  end

  private

  def run_task
    capture_io { load TASK }
  end

  def attach_legacy_image(user, suffix)
    user.owned_images.create!(
      imageable: user,
      url: "https://imagedelivery.net/mockhash/avatar-#{suffix}/public"
    )
  end
end
