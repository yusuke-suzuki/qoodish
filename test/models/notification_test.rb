require 'test_helper'

class NotificationTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test 'web push on create' do
    assert_enqueued_with(job: BroadcastWebPushJob) do
      Notification.create!(
        notifiable: pins(:public_you_one),
        notifier: users(:me),
        recipient: pins(:public_you_one).user,
        key: 'liked'
      )
    end

    notification = Notification.last
    assert_equal notification.notifiable, pins(:public_you_one)
    assert_equal notification.notifier, users(:me)
    assert_equal notification.recipient, pins(:public_you_one).user
    assert_equal notification.key, 'liked'

    perform_enqueued_jobs
  end

  test 'web push without stored preferences by default' do
    assert_empty users(:you).preferences

    assert_enqueued_with(job: BroadcastWebPushJob) do
      Notification.create!(
        notifiable: pins(:public_you_one),
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
        notifiable: pins(:public_you_one),
        notifier: users(:me),
        recipient: users(:you),
        key: 'liked'
      )
    end
  end

  test 'a liked pin links to the pin' do
    notification = Notification.new(
      notifiable: pins(:public_you_one),
      notifier: users(:me),
      recipient: users(:you),
      key: 'liked'
    )

    assert_equal "/pins/#{pins(:public_you_one).id}", notification.click_action
  end

  test 'a comment links to the commented pin' do
    notification = Notification.new(
      notifiable: pins(:public_one),
      notifier: users(:you),
      recipient: users(:me),
      key: 'comment'
    )

    assert_equal "/pins/#{pins(:public_one).id}", notification.click_action
  end

  test 'a liked comment links to its pin' do
    notification = Notification.new(
      notifiable: comments(:one),
      notifier: users(:you),
      recipient: users(:me),
      key: 'liked'
    )

    assert_equal "/pins/#{pins(:public_one).id}", notification.click_action
  end

  test 'a pin is still named review for the clients that expect it' do
    notification = Notification.new(
      notifiable: pins(:public_one),
      notifier: users(:you),
      recipient: users(:me),
      key: 'liked'
    )

    assert_equal 'review', notification.client_notifiable_type
  end

  test 'every other subject keeps its own name' do
    notification = Notification.new(
      notifiable: chapters(:you_published_on_my_map),
      notifier: users(:you),
      recipient: users(:me),
      key: 'published'
    )

    assert_equal 'chapter', notification.client_notifiable_type
  end

  test 'a notification of a deleted pin is not renderable' do
    notification = Notification.create!(
      notifiable: pins(:public_one),
      notifier: users(:you),
      recipient: users(:me),
      key: 'liked'
    )

    assert_predicate notification, :renderable?

    pins(:public_one).discard!(user: users(:me))

    assert_not notification.reload.renderable?
  end

  test 'a notification of a chapter reverted to draft is still renderable' do
    chapter = chapters(:you_published_on_my_map)
    notification = Notification.create!(
      notifiable: chapter,
      notifier: users(:me),
      recipient: users(:you),
      key: 'liked'
    )

    chapter.revise!(user: users(:you), status: 'draft')

    assert_predicate notification.reload, :renderable?
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
