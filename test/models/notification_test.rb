require 'test_helper'

class NotificationTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test 'web push on create' do
    assert_enqueued_with(job: BloadcastWebPushJob) do
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
end
