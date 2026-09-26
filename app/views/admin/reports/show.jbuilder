json.partial! 'admin/reports/report', report: @report
json.status @report.status
json.locale @report.locale
json.details @report.details
json.content_snapshot @report.content_snapshot
json.target_available @report.moderatable.present?
json.moderatable_parent do
  parent = @report.moderatable_parent
  if parent
    json.type parent.class.name
    json.id parent.id
  else
    json.nil!
  end
end
json.edited_since_filed @report.edited_since_filed?
json.decisions @report.decisions.preload(:staff_member) do |decision|
  json.partial! 'admin/reports/decision', decision: decision
  json.reviewed_as_filed @report.reviewed_as_filed?(decision)
end
json.other_pending_reports @report.other_pending_reports.preload(:reporter),
                           partial: 'admin/reports/report',
                           as: :report
