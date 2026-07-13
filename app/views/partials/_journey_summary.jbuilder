json.id journey.id
json.map_id journey.map_id
json.started_at journey.started_at
json.finished_at journey.finished_at
json.milestones_count journey.milestones.length
json.checkins_count journey.checkins.length
json.chapter_id journey.chapter&.id
if journey.map.present?
  json.map do
    json.id journey.map_id
    json.name journey.map.name
    json.private journey.map.private
  end
else
  json.map nil
end
json.created_at journey.created_at
json.updated_at journey.updated_at
