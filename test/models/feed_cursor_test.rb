require 'test_helper'

class FeedCursorTest < ActiveSupport::TestCase
  test 'parses a timestamp without an id into a strict boundary' do
    cursor = FeedCursor.new('2026-06-08T00:00:00Z')

    assert_equal Time.zone.parse('2026-06-08T00:00:00Z'), cursor.created_at
    assert_nil cursor.id
    assert_equal ['pins.created_at < ?', cursor.created_at], cursor.condition('pins')
  end

  test 'keeps the microseconds a serialized timestamp carries' do
    time = Time.zone.parse('2026-06-08T00:00:00.123456Z')

    assert_equal time, FeedCursor.new(time.as_json).created_at
  end

  test 'carries the id into a composite boundary' do
    cursor = FeedCursor.new('2026-06-08T00:00:00Z', '42')

    assert_equal 42, cursor.id
    sql, binds = cursor.condition('chapters')
    assert_match(/chapters\.created_at = :created_at AND chapters\.id < :id/, sql)
    assert_equal({ created_at: cursor.created_at, id: 42 }, binds)
  end

  test 'rejects a cursor that is not a time' do
    assert_raises(Exceptions::BadRequest) { FeedCursor.new('yesterday-ish') }
    assert_raises(Exceptions::BadRequest) { FeedCursor.new('') }
    assert_raises(Exceptions::BadRequest) { FeedCursor.new(nil) }
  end
end
