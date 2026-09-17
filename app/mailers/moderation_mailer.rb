class ModerationMailer < ApplicationMailer
  # The operator mail is an internal ops notice, so it stays in the repository
  # language rather than following the reporter's locale.
  def report_received(report)
    @report = report

    I18n.with_locale(I18n.default_locale) do
      mail(to: Report.operator_email, subject: default_i18n_subject(id: report.id))
    end
  end

  def report_acknowledged(report)
    @report = report

    I18n.with_locale(report.locale) do
      mail(to: report.reporter_address, subject: default_i18n_subject(id: report.id))
    end
  end

  def decision_notified(report, decision)
    @report = report
    @decision = decision

    I18n.with_locale(report.locale) do
      mail(to: report.reporter_address, subject: default_i18n_subject(id: report.id))
    end
  end

  def content_removed(decision)
    @decision = decision
    @author = decision.author

    I18n.with_locale(@author.notification_locale) do
      mail(to: @author.email, subject: default_i18n_subject)
    end
  end
end
