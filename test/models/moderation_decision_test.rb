require 'test_helper'

class ModerationDecisionTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  test 'every attribute a decision can fail on is named in each locale' do
    attributes = ModerationDecision.validators.flat_map(&:attributes).uniq

    I18n.available_locales.each do |locale|
      attributes.each do |attribute|
        assert I18n.exists?("activerecord.attributes.moderation_decision.#{attribute}", locale),
               "#{locale} has no name for ModerationDecision##{attribute}"
      end
    end
  end

  test 'every error message is worded in each locale' do
    I18n.available_locales.combination(2).each do |one, other|
      assert_equal error_message_keys(:moderation_decision, one), error_message_keys(:moderation_decision, other),
                   "#{one} and #{other} word different ModerationDecision errors"
    end
  end

  test 'keeping the content records the reason and tells the reporter' do
    report = Report.create!(moderatable: pins(:public_you_one), reporter: users(:me), category: 'spam')

    decision = nil

    assert_enqueued_emails 1 do
      decision = report.decide!(staff_member: staff_members(:moderator), outcome: 'kept', reason: 'Not spam.')
    end

    assert decision.kept?
    assert_equal users(:you), decision.author
    assert_equal staff_members(:moderator), decision.staff_member
    assert_equal 'Not spam.', decision.reason
    assert_includes decision.answered_reports, report
  end

  test 'removing the content hides it without destroying it' do
    pin = pins(:public_you_one)
    report = Report.create!(moderatable: pin, reporter: users(:me), category: 'hate')

    decision = nil

    assert_enqueued_emails 2 do
      decision = report.decide!(staff_member: staff_members(:moderator), outcome: 'removed', reason: 'Hate speech.')
    end

    assert decision.removed?
    assert_not_includes Pin.public_open, pin
    assert Pin.exists?(pin.id)
    assert_equal users(:you), decision.author
    assert_includes decision.content_snapshot, pin.comment
  end

  test 'keeping content that was hidden brings it back' do
    pin = pins(:public_you_one)
    decide(pin, outcome: 'removed', reason: 'Hate speech.')

    assert_not_includes Pin.public_open, pin

    travel 1.minute
    decide(pin, outcome: 'kept', reason: 'Objection upheld.')

    assert_includes Pin.public_open, pin
  end

  test 'an account with hidden content can still be deleted' do
    decide(pins(:public_you_one), outcome: 'removed', reason: 'Hate speech.')

    stub_identity_platform { users(:you).destroy! }

    assert_not User.exists?(users(:you).id)
    assert_not Pin.exists?(pins(:public_you_one).id)
  end

  test 'hidden content can no longer be reported' do
    pin = pins(:public_you_one)
    decide(pin, outcome: 'removed', reason: 'Hate speech.')

    assert_raises(ActiveRecord::RecordNotFound) do
      Report.moderatable_for(Pin.name, pin.id, users(:me))
    end
  end

  test 'a hidden comment can no longer be reported' do
    comment = comments(:two)
    decide(comment, outcome: 'removed', reason: 'Harassment.')

    assert_raises(ActiveRecord::RecordNotFound) do
      Report.moderatable_for(Comment.name, comment.id, users(:me))
    end
  end

  test 'a report whose target is gone is closed as unavailable' do
    pin = pins(:public_you_one)
    report = Report.create!(moderatable: pin, reporter: users(:me), category: 'spam')

    stub_identity_platform { users(:you).destroy! }

    decision = report.reload.decide!(staff_member: staff_members(:moderator), outcome: 'unavailable',
                                     reason: 'The author deleted the account.')

    assert decision.unavailable?
    assert_equal report.content_snapshot, decision.content_snapshot
    assert_equal report.reported_revision_id, decision.reviewed_revision_id
    assert report.reviewed_as_filed?(decision)
    assert_not_includes Report.pending, report
    assert_equal 'unavailable', report.status
  end

  test 'a report whose target is gone can be neither kept nor removed' do
    report = Report.create!(moderatable: pins(:public_you_one), reporter: users(:me), category: 'spam')
    stub_identity_platform { users(:you).destroy! }

    %w[kept removed].each do |outcome|
      error = assert_raises(ActiveRecord::RecordInvalid) do
        report.reload.decide!(staff_member: staff_members(:moderator), outcome: outcome, reason: 'x')
      end

      assert error.record.errors.added?(:moderatable, :blank)
    end
  end

  test 'an unknown outcome is refused' do
    report = Report.create!(moderatable: pins(:public_you_one), reporter: users(:me), category: 'spam')

    error = assert_raises(ActiveRecord::RecordInvalid) do
      report.decide!(staff_member: staff_members(:moderator), outcome: 'deleted', reason: 'x')
    end

    assert error.record.errors.added?(:outcome, :inclusion, value: 'deleted')
  end

  test 'a decision without a staff member is refused' do
    report = Report.create!(moderatable: pins(:public_you_one), reporter: users(:me), category: 'spam')

    error = assert_raises(ActiveRecord::RecordInvalid) do
      report.decide!(staff_member: nil, outcome: 'kept', reason: 'x')
    end

    assert error.record.errors.added?(:staff_member, :blank)
    assert_includes Report.pending, report
  end

  test 'closing a report whose target is still there is refused' do
    report = Report.create!(moderatable: pins(:public_you_one), reporter: users(:me), category: 'spam')

    error = assert_raises(ActiveRecord::RecordInvalid) do
      report.decide!(staff_member: staff_members(:moderator), outcome: 'unavailable', reason: 'x')
    end

    assert error.record.errors.added?(:moderatable, :present)

    assert_includes Report.pending, report
  end

  test 'two decisions sharing a timestamp answer different reports' do
    now = Time.current.change(usec: 0)
    first = Report.create!(moderatable: pins(:public_you_one), reporter: users(:me), category: 'spam',
                           created_at: now - 1.minute)
    earlier = ModerationDecision.create!(moderatable: pins(:public_you_one), author: users(:you),
                                         staff_member: staff_members(:moderator),
                                         outcome: 'kept', reason: 'Not spam.', created_at: now)
    second = Report.create!(moderatable: pins(:public_you_one), reporter: record_user('second'),
                            category: 'hate', created_at: now)
    later = ModerationDecision.create!(moderatable: pins(:public_you_one), author: users(:you),
                                       staff_member: staff_members(:moderator),
                                       outcome: 'kept', reason: 'Still fine.', created_at: now)

    assert_equal earlier, later.previous
    assert_includes later.answered_reports, second
    assert_not_includes later.answered_reports, first
  end

  test 'a removal hides a chapter from its own author' do
    chapter = chapters(:my_draft)

    assert_includes Chapter.readable_by(users(:me)), chapter

    decide(chapter, outcome: 'removed', reason: 'Hate speech.')

    assert_not_includes Chapter.readable_by(users(:me)), chapter
  end

  test 'hiding a map takes its pins with it' do
    map = maps(:public_unfollowing)
    pin = map.pins.first

    decide(map, outcome: 'removed', reason: 'Spam map.')

    assert_not_includes Map.public_open, map
    assert_not_includes Pin.public_open, pin
  end

  test 'a recorded decision can never be updated' do
    decision = decide(pins(:public_you_one), outcome: 'kept', reason: 'Not spam.')

    assert_raises(ActiveRecord::ReadOnlyRecord) { decision.update!(reason: 'Changed my mind.') }
  end

  test 'an account and a journal are not removed through moderation' do
    [users(:you), journals(:you_journal)].each do |moderatable|
      error = assert_raises(ActiveRecord::RecordInvalid) do
        decide(moderatable, outcome: 'removed', reason: 'x')
      end

      assert error.record.errors.of_kind?(:moderatable_type, :exclusion)
    end
  end

  test 'a refused removal reads as one Japanese sentence' do
    error = assert_raises(ActiveRecord::RecordInvalid) do
      decide(users(:you), outcome: 'removed', reason: 'x')
    end

    I18n.with_locale(:ja) do
      assert_equal ['対象の種類がアカウントか手帳の場合は、非表示にできません。「対象を維持する」を選んでください。'],
                   error.record.errors.full_messages
    end
  end

  test 'a decision answers only the reports filed since the previous one' do
    first = Report.create!(moderatable: pins(:public_you_one), reporter: users(:me), category: 'spam')
    first.decide!(staff_member: staff_members(:moderator), outcome: 'kept', reason: 'Not spam.')
    travel 1.minute
    second = Report.create!(moderatable: pins(:public_you_one), reporter: record_user('second'), category: 'hate')
    travel 1.minute
    later = second.decide!(staff_member: staff_members(:moderator), outcome: 'kept', reason: 'Still fine.')

    assert_includes later.answered_reports, second
    assert_not_includes later.answered_reports, first
  end

  test 'deleting the author keeps the decision' do
    decision = decide(pins(:public_you_one), outcome: 'kept', reason: 'Not spam.')

    stub_identity_platform { users(:you).destroy! }

    assert_nil decision.reload.author_id
    assert_equal 'Not spam.', decision.reason
  end
end
