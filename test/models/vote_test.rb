require 'test_helper'

class VoteTest < ActiveSupport::TestCase
  test 'liking the content of another user notifies them' do
    assert_difference 'Notification.count', 1 do
      users(:me).liked!(chapters(:you_published))
    end

    notification = Notification.last

    assert_equal 'liked', notification.key
    assert_equal users(:you), notification.recipient
  end

  test 'liking again after unliking notifies only once' do
    assert_difference 'Notification.count', 1 do
      users(:me).liked!(chapters(:you_published))
    end

    users(:me).unliked!(chapters(:you_published))

    assert_no_difference 'Notification.count' do
      users(:me).liked!(chapters(:you_published))
    end
  end

  test 'liking your own content notifies nobody' do
    assert_difference 'Vote.count' => 1, 'Notification.count' => 0 do
      users(:me).liked!(chapters(:my_published))
    end
  end
end
