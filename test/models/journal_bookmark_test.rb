require 'test_helper'

class JournalBookmarkTest < ActiveSupport::TestCase
  test 'valid bookmark on a journal of another user' do
    bookmark = JournalBookmark.new(
      journal: journals(:my_journal),
      user: users(:you)
    )

    assert bookmark.valid?
  end

  test 'duplicate bookmark is invalid' do
    bookmark = JournalBookmark.new(
      journal: journals(:you_journal),
      user: users(:me)
    )

    assert_not bookmark.valid?
  end

  test 'author cannot bookmark own journal' do
    bookmark = JournalBookmark.new(
      journal: journals(:my_journal),
      user: users(:me)
    )

    assert_not bookmark.valid?
  end
end
