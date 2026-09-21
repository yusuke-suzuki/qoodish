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

  test 'the default journal starts with a revision of its own' do
    stub_identity_platform do
      user = User.create!(uid: 'journal-revision-uid', name: 'Journal Tester')
      journal = user.journal

      assert_equal 1, journal.revisions.count
      assert_equal journal.revisions.last, journal.current_revision
      assert_equal user, journal.current_revision.user
      assert_equal "Journal Tester's journal", journal.current_revision.title
    end
  end

  test 'revise! appends a revision and leaves the previous one untouched' do
    journal = journals(:my_journal)
    previous = journal.current_revision

    journal.revise!(user: users(:me), title: 'Renamed journal')

    assert_equal 'Renamed journal', journal.reload.title
    assert_equal 2, journal.revisions.count
    assert_equal journal.revisions.last, journal.current_revision
    assert_equal 'My adventure journal', previous.reload.title
  end

  test 'the log keeps a description that was cleared' do
    journal = journals(:my_journal)

    journal.revise!(user: users(:me), description: '')

    assert_equal '', journal.reload.description
    assert_equal 'Notes from my adventures.', journal.revisions.first.description
  end

  test 'revising with what the journal already says appends nothing' do
    journal = journals(:my_journal)

    assert_no_difference -> { journal.revisions.count } do
      journal.revise!(user: users(:me), title: journal.title, description: journal.description)
      journal.revise!(user: users(:me))
    end
  end

  test 'a revision cannot be rewritten' do
    revision = journals(:my_journal).current_revision

    assert_raises(ActiveRecord::ReadonlyAttributeError) { revision.update!(title: 'rewritten') }
  end

  test 'the title cannot be changed outside a revision' do
    journal = journals(:my_journal)

    assert_raises(ActiveRecord::ReadOnlyRecord) { journal.update!(title: 'Renamed') }
    assert_equal 'My adventure journal', journal.reload.title
  end

  test 'a journal cannot be created outside a revision' do
    stub_identity_platform do
      user = User.create!(uid: 'journal-guard-uid', name: 'Journal Tester')
      user.journal.destroy!

      assert_raises(ActiveRecord::ReadOnlyRecord) do
        Journal.create!(user: user.reload, title: 'Sneaked in')
      end
    end
  end

  test 'a journal is not handed discard!' do
    assert_not_respond_to journals(:my_journal), :discard!
  end

  test 'erasing an account destroys the journal revisions it wrote' do
    assert_difference 'JournalRevision.count', -1 do
      stub_identity_platform { users(:you).destroy! }
    end
  end
end
