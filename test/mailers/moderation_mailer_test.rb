require 'test_helper'

class ModerationMailerTest < ActionMailer::TestCase
  setup do
    @report = Report.create!(
      moderatable: reviews(:public_you_one),
      reporter: users(:me),
      category: 'harassment',
      details: 'Targets me by name.'
    )
  end

  test 'report_received goes to the operator with the details and the snapshot' do
    mail = ModerationMailer.report_received(@report)

    assert_equal [Report.operator_email], mail.to
    assert_includes mail.subject, "##{@report.id}"
    assert_includes mail.body.decoded, 'Targets me by name.'
    assert_includes mail.body.decoded, reviews(:public_you_one).comment
    assert_includes mail.body.decoded, "moderation:show[#{@report.id}]"
  end

  test 'report_acknowledged answers the reporter in the locale of the report' do
    mail = ModerationMailer.report_acknowledged(@report)

    assert_equal [users(:me).email], mail.to
    assert_includes mail.subject, 'We received your report'
    assert_includes mail.body.decoded, 'Harassment or bullying'
  end

  test 'report_acknowledged answers a Japanese reporter in Japanese' do
    RequestContext.locale = 'ja'
    japanese_report = Report.create!(moderatable: reviews(:public_you_one), reporter_email: 'guest@example.com',
                                     category: 'harassment')

    mail = ModerationMailer.report_acknowledged(japanese_report)

    assert_includes mail.subject, '報告を受け付けました'
    assert_includes mail.body.decoded, '嫌がらせ・いじめ'
  end

  test 'decision_notified tells the reporter the outcome and the reason' do
    decision = ModerationDecision.keep!(moderatable: reviews(:public_you_one), reason: 'Not harassment.')

    mail = ModerationMailer.decision_notified(@report, decision)

    assert_equal [users(:me).email], mail.to
    assert_includes mail.body.decoded, 'No removal or other measure was taken.'
    assert_includes mail.body.decoded, 'Not harassment.'
  end

  test 'content_removed tells the author what was removed and why' do
    comment = reviews(:public_you_one).comment
    decision = ModerationDecision.remove!(moderatable: reviews(:public_you_one), reason: 'Harassment.')

    mail = ModerationMailer.content_removed(decision)

    assert_equal [users(:you).email], mail.to
    assert_includes mail.body.decoded, comment
    assert_includes mail.body.decoded, 'Harassment.'
  end

  test 'content_removed follows the locale recorded on the author' do
    users(:you).update!(locale: 'ja')
    decision = ModerationDecision.remove!(moderatable: reviews(:public_you_one).reload, reason: 'Harassment.')

    mail = ModerationMailer.content_removed(decision)

    assert_includes mail.subject, '投稿を削除しました'
    assert_includes mail.body.decoded, '異議を申し出ることができます'
  end
end
