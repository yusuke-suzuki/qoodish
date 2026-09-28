require "test_helper"

class BroadcastWebPushJobTest < ActiveJob::TestCase
  test 'a push queued before the recipient mutes the notifier is not sent' do
    notification = Notification.create!(
      notifiable: pins(:public_you_one),
      notifier: users(:me),
      recipient: users(:you),
      key: 'liked'
    )
    users(:you).mute!(users(:me))

    notification.stub(:broadcast_web_push, -> { flunk 'sent a push the recipient no longer allows' }) do
      BroadcastWebPushJob.perform_now(notification)
    end
  end
end
