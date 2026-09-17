require 'test_helper'

class ModerationDecisionTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  test 'keeping the content records the reason and tells the reporter' do
    report = Report.create!(moderatable: pins(:public_you_one), reporter: users(:me), category: 'spam')

    decision = nil

    assert_enqueued_emails 1 do
      decision = ModerationDecision.keep!(moderatable: pins(:public_you_one), reason: 'Not spam.')
    end

    assert decision.kept?
    assert_equal users(:you), decision.author
    assert_nil decision.moderator
    assert_equal 'Not spam.', decision.reason
    assert_includes decision.answered_reports, report
  end

  test 'removing the content hides it without destroying it' do
    pin = pins(:public_you_one)
    Report.create!(moderatable: pin, reporter: users(:me), category: 'hate')

    decision = nil

    assert_enqueued_emails 2 do
      decision = ModerationDecision.remove!(moderatable: pin, reason: 'Hate speech.')
    end

    assert decision.removed?
    assert_not_includes Pin.public_open, pin
    assert Pin.exists?(pin.id)
    assert_equal users(:you), decision.author
    assert_includes decision.content_snapshot, pin.comment
  end

  test 'keeping content that was hidden brings it back' do
    pin = pins(:public_you_one)
    ModerationDecision.remove!(moderatable: pin, reason: 'Hate speech.')

    assert_not_includes Pin.public_open, pin

    travel 1.minute
    ModerationDecision.keep!(moderatable: pin, reason: 'Objection upheld.')

    assert_includes Pin.public_open, pin
  end

  test 'an account with hidden content can still be deleted' do
    ModerationDecision.remove!(moderatable: pins(:public_you_one), reason: 'Hate speech.')

    stub_identity_platform { users(:you).destroy! }

    assert_not User.exists?(users(:you).id)
    assert_not Pin.exists?(pins(:public_you_one).id)
  end

  test 'hidden content can no longer be reported' do
    pin = pins(:public_you_one)
    ModerationDecision.remove!(moderatable: pin, reason: 'Hate speech.')

    assert_raises(ActiveRecord::RecordNotFound) do
      Report.moderatable_for(Pin.name, pin.id, users(:me))
    end
  end

  test 'a hidden comment can no longer be reported' do
    comment = comments(:two)
    ModerationDecision.remove!(moderatable: comment, reason: 'Harassment.')

    assert_raises(ActiveRecord::RecordNotFound) do
      Report.moderatable_for(Comment.name, comment.id, users(:me))
    end
  end

  test 'a report whose target is gone is closed as unavailable' do
    pin = pins(:public_you_one)
    report = Report.create!(moderatable: pin, reporter: users(:me), category: 'spam')

    stub_identity_platform { users(:you).destroy! }

    decision = ModerationDecision.close_unavailable!(report: report.reload, reason: 'The author deleted the account.')

    assert decision.unavailable?
    assert_equal report.content_snapshot, decision.content_snapshot
    assert_equal report.reported_revision_id, decision.reviewed_revision_id
    assert report.reviewed_as_filed?(decision)
    assert_not_includes Report.pending, report
    assert_equal 'unavailable', report.status
  end

  test 'deciding on a target that is gone is refused' do
    assert_raises(ArgumentError) { ModerationDecision.keep!(moderatable: nil, reason: 'x') }
    assert_raises(ArgumentError) { ModerationDecision.remove!(moderatable: nil, reason: 'x') }
  end

  test 'closing a report whose target is still there is refused' do
    report = Report.create!(moderatable: pins(:public_you_one), reporter: users(:me), category: 'spam')

    assert_raises(ArgumentError) do
      ModerationDecision.close_unavailable!(report: report, reason: 'x')
    end

    assert_includes Report.pending, report
  end

  test 'two decisions sharing a timestamp answer different reports' do
    now = Time.current.change(usec: 0)
    first = Report.create!(moderatable: pins(:public_you_one), reporter: users(:me), category: 'spam',
                           created_at: now - 1.minute)
    earlier = ModerationDecision.create!(moderatable: pins(:public_you_one), author: users(:you),
                                         outcome: 'kept', reason: 'Not spam.', created_at: now)
    second = Report.create!(moderatable: pins(:public_you_one), reporter_email: 'guest@example.com',
                            category: 'hate', created_at: now)
    later = ModerationDecision.create!(moderatable: pins(:public_you_one), author: users(:you),
                                       outcome: 'kept', reason: 'Still fine.', created_at: now)

    assert_equal earlier, later.previous
    assert_includes later.answered_reports, second
    assert_not_includes later.answered_reports, first
  end

  test 'a removal hides a chapter from its own author' do
    chapter = chapters(:my_draft)

    assert_includes Chapter.readable_by(users(:me)), chapter

    ModerationDecision.remove!(moderatable: chapter, reason: 'Hate speech.')

    assert_not_includes Chapter.readable_by(users(:me)), chapter
  end

  test 'hiding a map takes its pins with it' do
    map = maps(:public_unfollowing)
    pin = map.pins.first

    ModerationDecision.remove!(moderatable: map, reason: 'Spam map.')

    assert_not_includes Map.public_open, map
    assert_not_includes Pin.public_open, pin
  end

  test 'a recorded decision can never be updated' do
    decision = ModerationDecision.keep!(moderatable: pins(:public_you_one), reason: 'Not spam.')

    assert_raises(ActiveRecord::ReadOnlyRecord) { decision.update!(reason: 'Changed my mind.') }
  end

  test 'an account and a journal are not removed through moderation' do
    assert_raises(ArgumentError) do
      ModerationDecision.remove!(moderatable: users(:you), reason: 'x')
    end
    assert_raises(ArgumentError) do
      ModerationDecision.remove!(moderatable: journals(:you_journal), reason: 'x')
    end
  end

  test 'a decision answers only the reports filed since the previous one' do
    first = Report.create!(moderatable: pins(:public_you_one), reporter: users(:me), category: 'spam')
    ModerationDecision.keep!(moderatable: pins(:public_you_one), reason: 'Not spam.')
    travel 1.minute
    second = Report.create!(moderatable: pins(:public_you_one), reporter_email: 'guest@example.com',
                            category: 'hate')
    travel 1.minute
    later = ModerationDecision.keep!(moderatable: pins(:public_you_one), reason: 'Still fine.')

    assert_includes later.answered_reports, second
    assert_not_includes later.answered_reports, first
  end

  test 'a decision without a moderator is recorded as made by the system' do
    decision = ModerationDecision.keep!(moderatable: pins(:public_you_one), reason: 'Automated check passed.')

    assert_nil decision.moderator_id
  end

  test 'deleting the author keeps the decision' do
    decision = ModerationDecision.keep!(moderatable: pins(:public_you_one), reason: 'Not spam.')

    stub_identity_platform { users(:you).destroy! }

    assert_nil decision.reload.author_id
    assert_equal 'Not spam.', decision.reason
  end
end
