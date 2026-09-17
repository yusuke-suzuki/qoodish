namespace :moderation do
  desc 'List reports that are still waiting for a decision'
  task pending: :environment do
    Report.pending.find_each(cursor: %i[created_at id], order: %i[asc asc]) do |report|
      puts [
        "##{report.id}",
        report.category,
        "#{report.moderatable_type} #{report.moderatable_id}",
        report.reporter ? "user #{report.reporter_id}" : "guest #{report.reporter_email}",
        report.created_at.utc.iso8601
      ].join("\t")
    end
  end

  desc 'Show one report with its details, content snapshot and decision history'
  task :show, [:report_id] => :environment do |_task, args|
    report = Report.find(args.fetch(:report_id))
    decisions = ModerationDecision
                .where(moderatable_type: report.moderatable_type, moderatable_id: report.moderatable_id)
                .order(:created_at, :id)
    decision_lines = decisions.map do |decision|
      [
        decision.created_at.utc.iso8601,
        decision.outcome,
        report.reviewed_as_filed?(decision) ? 'as reported' : 'other revision',
        decision.reason
      ].join("\t")
    end

    puts <<~REPORT
      Report:       ##{report.id}
      Status:       #{report.status}
      Category:     #{report.category}
      Target:       #{report.moderatable_type} #{report.moderatable_id}#{report.moderatable.blank? ? ' (gone)' : ''}
      Reporter:     #{report.reporter ? "user #{report.reporter_id} (#{report.reporter.name})" : "guest #{report.reporter_email}"}
      Locale:       #{report.locale}
      Filed at:     #{report.created_at.utc.iso8601}
      Edited since: #{report.edited_since_filed? ? 'yes, the content changed after this report' : 'no'}
      Evidence URL: #{report.evidence_url.presence || '(none)'}

      Details:
      #{report.details.presence || '(none)'}

      Content snapshot:
      #{report.content_snapshot.presence || '(none)'}

      Decisions:
      #{decision_lines.presence&.join("\n") || '(none)'}
    REPORT
  end

  desc 'Decide that the reported content stays, restoring it if it was hidden'
  task :keep, %i[report_id reason] => :environment do |_task, args|
    report = Report.find(args.fetch(:report_id))

    ModerationDecision.keep!(moderatable: report.moderatable, reason: args.fetch(:reason))
  end

  desc 'Hide the reported content, and tell the reporters and the author why'
  task :remove, %i[report_id reason] => :environment do |_task, args|
    report = Report.find(args.fetch(:report_id))

    ModerationDecision.remove!(moderatable: report.moderatable, reason: args.fetch(:reason))
  end

  desc 'Close a report whose target no longer exists'
  task :close, %i[report_id reason] => :environment do |_task, args|
    report = Report.find(args.fetch(:report_id))

    ModerationDecision.close_unavailable!(report: report, reason: args.fetch(:reason))
  end
end
