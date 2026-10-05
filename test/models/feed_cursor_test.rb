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

  test 'decodes the token it encodes back into the same boundary' do
    time = Time.zone.parse('2026-06-08T00:00:00.123456Z')
    cursor = FeedCursor.decode(FeedCursor.new(time.iso8601(6), 42).encode)

    assert_equal time, cursor.created_at
    assert_equal 42, cursor.id
  end

  test 'hands out a token only when the page is full' do
    pins = Pin.order(:id).first(2)

    assert_nil FeedCursor.next_token(pins, 3)
    assert_equal pins.last.id, FeedCursor.decode(FeedCursor.next_token(pins, 2)).id
  end

  test 'rejects a token it did not encode' do
    assert_raises(Exceptions::BadRequest) { FeedCursor.decode('not-a-cursor') }
    assert_raises(Exceptions::BadRequest) { FeedCursor.decode(Base64.urlsafe_encode64('2026-06-08T00:00:00Z')) }
    assert_raises(Exceptions::BadRequest) { FeedCursor.decode(Base64.urlsafe_encode64("\xFF\xFE,1")) }
    assert_raises(Exceptions::BadRequest) { FeedCursor.decode(Base64.urlsafe_encode64('2026-06-08T00:00:00Z,abc')) }
    assert_raises(Exceptions::BadRequest) { FeedCursor.decode(Base64.urlsafe_encode64('2026-06-08T00:00:00Z,0')) }
  end

  test 'rejects a cursor that is not a time' do
    assert_raises(Exceptions::BadRequest) { FeedCursor.new('yesterday-ish') }
    assert_raises(Exceptions::BadRequest) { FeedCursor.new('') }
    assert_raises(Exceptions::BadRequest) { FeedCursor.new(nil) }
  end
end
