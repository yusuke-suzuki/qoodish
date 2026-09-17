require 'test_helper'

class ReportTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  test 'a signed-in reporter files a report on a pin they can reference' do
    report = Report.create!(
      moderatable: pins(:public_you_one),
      reporter: users(:me),
      category: 'spam'
    )

    assert_equal 'pending', report.status
    assert_equal users(:you), report.author
    assert_equal 'en', report.locale
    assert_includes report.content_snapshot, pins(:public_you_one).comment
  end

  test 'a report records the locale the reporter was reading in' do
    RequestContext.locale = 'ja'

    report = Report.create!(moderatable: pins(:public_you_one), reporter: users(:me), category: 'spam')

    assert_equal 'ja', report.locale
  end

  test 'a filed report can never be updated' do
    report = Report.create!(moderatable: pins(:public_you_one), reporter: users(:me), category: 'spam')

    assert_raises(ActiveRecord::ReadOnlyRecord) { report.update!(category: 'hate') }
  end

  test 'a guest files a report with an email' do
    report = Report.create!(
      moderatable: pins(:public_you_one),
      reporter_email: ' Someone@Example.com ',
      category: 'harassment'
    )

    assert_nil report.reporter
    assert_equal 'someone@example.com', report.reporter_address
  end

  test 'copyright, privacy and other reports need details' do
    Report::DETAILS_REQUIRED_CATEGORIES.each do |category|
      report = Report.new(moderatable: pins(:public_you_one), reporter: users(:me), category: category)

      assert_not report.valid?
      assert_includes report.errors[:details], I18n.t('messages.api.report_details_required')
    end
  end

  test 'a guest report needs an email so the outcome can be sent' do
    report = Report.new(moderatable: pins(:public_you_one), category: 'spam')

    assert_not report.valid?
    assert_includes report.errors[:reporter_email], I18n.t('messages.api.report_email_required')
  end

  test 'an author cannot report their own content' do
    report = Report.new(moderatable: pins(:public_one), reporter: users(:me), category: 'spam')

    assert_not report.valid?
    assert_includes report.errors[:moderatable], I18n.t('messages.api.report_own_content')
  end

  test 'a reporter files one report per content' do
    Report.create!(moderatable: pins(:public_you_one), reporter: users(:me), category: 'spam')
    duplicate = Report.new(moderatable: pins(:public_you_one), reporter: users(:me), category: 'hate')

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:reporter_id], I18n.t('messages.api.duplicate_report')
  end

  test 'a guest files one report per content' do
    Report.create!(moderatable: pins(:public_you_one), reporter_email: 'someone@example.com', category: 'spam')
    duplicate = Report.new(moderatable: pins(:public_you_one), reporter_email: 'Someone@example.com',
                           category: 'hate')

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:reporter_email], I18n.t('messages.api.duplicate_report')
  end

  test 'a rejection is worded in the language the reporter was reading in' do
    report = Report.new(moderatable: pins(:public_you_one), reporter: users(:me), category: 'copyright')

    message = I18n.with_locale(:ja) do
      report.valid?
      report.errors[:details].first
    end

    assert_equal I18n.t('messages.api.report_details_required', locale: :ja), message
  end

  test 'the status of a report is the decision that answered it, not a later one' do
    report = Report.create!(moderatable: pins(:public_you_one), reporter: users(:me), category: 'spam')
    ModerationDecision.keep!(moderatable: pins(:public_you_one), reason: 'Not spam.')
    travel 1.minute
    ModerationDecision.remove!(moderatable: pins(:public_you_one).reload, reason: 'Reported again since.')

    assert_equal 'kept', report.status
  end

  test 'a report that loses the race with an identical one is refused, not crashed' do
    Report.stub :create!, ->(*) { raise ActiveRecord::RecordNotUnique, 'duplicate entry' } do
      error = assert_raises(Exceptions::UnprocessableContent) do
        Report.file!(moderatable: pins(:public_you_one), reporter: users(:me), category: 'spam')
      end

      assert_equal I18n.t('messages.api.duplicate_report'), error.message
    end
  end

  test 'an unknown type is refused before any lookup' do
    assert_raises(Exceptions::BadRequest) do
      Report.moderatable_for('Vote', votes(:public_one).id, users(:me))
    end
  end

  test 'a reporter reaches the content they can reference' do
    assert_equal pins(:private_following), Report.moderatable_for(Pin.name, pins(:private_following).id,
                                                                    users(:me))
    assert_equal journals(:you_journal), Report.moderatable_for(Journal.name, journals(:you_journal).id, users(:me))

    assert_raises(ActiveRecord::RecordNotFound) do
      Report.moderatable_for(Pin.name, pins(:private_unfollowing_you).id, users(:me))
    end
  end

  test 'the snapshot of a chapter is its text' do
    report = Report.create!(moderatable: chapters(:you_published), reporter: users(:me), category: 'spam')

    assert_includes report.content_snapshot, 'Your published chapter'
  end

  test 'filing a report mails the operator and the reporter' do
    assert_enqueued_emails 2 do
      Report.create!(moderatable: pins(:public_you_one), reporter: users(:me), category: 'spam')
    end
  end

  test 'a report waits until a decision lands on the content' do
    report = Report.create!(moderatable: pins(:public_you_one), reporter: users(:me), category: 'spam')

    assert_includes Report.pending, report

    ModerationDecision.keep!(moderatable: pins(:public_you_one), reason: 'Not spam.')

    assert_equal 'kept', report.status
    assert_not_includes Report.pending, report
  end

  test 'a decision made before the report leaves it waiting' do
    ModerationDecision.keep!(moderatable: pins(:public_you_one), reason: 'Looked fine.')
    travel 1.minute
    report = Report.create!(moderatable: pins(:public_you_one), reporter: users(:me), category: 'spam')

    assert_equal 'pending', report.status
    assert_includes Report.pending, report
  end

  test 'the snapshot of a pin keeps the images that were reported' do
    report = Report.create!(moderatable: pins(:public_one), reporter: users(:you), category: 'sexual')

    assert_includes report.content_snapshot, images(:one).url
    assert_includes report.content_snapshot, images(:two).url
  end

  test 'a report remembers the revision the reporter saw' do
    pin = pins(:public_you_one)

    report = Report.create!(moderatable: pin, reporter: users(:me), category: 'spam')

    assert_equal pin.current_revision_id, report.reported_revision_id
    assert_not report.edited_since_filed?
  end

  test 'an edit after the report is visible to the moderator' do
    pin = pins(:public_you_one)
    report = Report.create!(moderatable: pin, reporter: users(:me), category: 'spam')

    pin.revise!(user: users(:you), comment: 'Rewritten after the report.')

    assert report.reload.edited_since_filed?
  end

  test 'a decision on the reported revision is told apart from one on a later revision' do
    pin = pins(:public_you_one)
    report = Report.create!(moderatable: pin, reporter: users(:me), category: 'spam')
    as_reported = ModerationDecision.keep!(moderatable: pin, reason: 'Not spam.')

    pin.revise!(user: users(:you), comment: 'Rewritten after the decision.')
    travel 1.minute
    after_edit = ModerationDecision.keep!(moderatable: pin.reload, reason: 'Still fine.')

    assert report.reviewed_as_filed?(as_reported)
    assert_not report.reviewed_as_filed?(after_edit)
  end

  test 'deleting the reporter keeps the report' do
    report = Report.create!(moderatable: pins(:public_you_one), reporter: users(:me), category: 'spam')

    stub_identity_platform { users(:me).destroy! }

    assert_nil report.reload.reporter_id
  end
end
