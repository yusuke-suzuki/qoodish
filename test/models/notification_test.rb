require 'test_helper'

class NotificationTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test 'web push on create' do
    assert_enqueued_with(job: BroadcastWebPushJob) do
      Notification.create!(
        notifiable: reviews(:public_you_one),
        notifier: users(:me),
        recipient: reviews(:public_you_one).user,
        key: 'liked'
      )
    end

    notification = Notification.last
    assert_equal notification.notifiable, reviews(:public_you_one)
    assert_equal notification.notifier, users(:me)
    assert_equal notification.recipient, reviews(:public_you_one).user
    assert_equal notification.key, 'liked'

    perform_enqueued_jobs
  end

  test 'web push without stored preferences by default' do
    assert_empty users(:you).preferences

    assert_enqueued_with(job: BroadcastWebPushJob) do
      Notification.create!(
        notifiable: reviews(:public_you_one),
        notifier: users(:me),
        recipient: users(:you),
        key: 'liked'
      )
    end
  end

  test 'no web push when the preference is disabled' do
    users(:you).update_web_push_preferences!('liked' => false)

    assert_no_enqueued_jobs do
      Notification.create!(
        notifiable: reviews(:public_you_one),
        notifier: users(:me),
        recipient: users(:you),
        key: 'liked'
      )
    end
  end

  test 'every key is gated by a preference of the same name' do
    assert_empty Notification::KEYS - UserPreference::WEB_PUSH_DEFAULTS.keys
  end

  test 'no web push when the published preference is disabled' do
    users(:me).update_web_push_preferences!('published' => false)

    assert_no_enqueued_jobs do
      Notification.create!(
        notifiable: chapters(:you_published_on_my_map),
        notifier: users(:you),
        recipient: users(:me),
        key: 'published'
      )
    end
  end
end
