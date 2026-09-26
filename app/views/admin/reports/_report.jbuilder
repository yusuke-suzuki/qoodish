json.id report.id
json.category report.category
json.moderatable_type report.moderatable_type
json.moderatable_id report.moderatable_id
json.reporter do
  if report.reporter
    json.id report.reporter.id
    json.name report.reporter.name
  else
    json.nil!
  end
end
json.created_at report.created_at
