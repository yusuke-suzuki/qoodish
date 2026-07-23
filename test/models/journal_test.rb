require 'test_helper'

class JournalTest < ActiveSupport::TestCase
  test 'fixture journal is valid' do
    assert journals(:my_journal).valid?
  end

  test 'user can have only one journal' do
    journal = Journal.new(
      user: users(:me),
      title: 'Second journal'
    )

    assert_not journal.valid?
  end

  test 'title is required' do
    journal = journals(:my_journal)
    journal.title = ''

    assert_not journal.valid?
  end

  test 'title cannot exceed 50 characters' do
    journal = journals(:my_journal)
    journal.title = 'a' * 51

    assert_not journal.valid?
  end

  test 'description cannot exceed 200 characters' do
    journal = journals(:my_journal)
    journal.description = 'a' * 201

    assert_not journal.valid?
  end

  test 'a new user gets a default journal' do
    stub_identity_platform do
      user = User.create!(uid: 'journal-test-uid', name: 'Journal Tester')

      assert_equal "Journal Tester's journal", user.journal.title
    end
  end
end
