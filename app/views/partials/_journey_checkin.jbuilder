json.id journey_checkin.id
json.review_id journey_checkin.review_id
json.spot do
  json.name journey_checkin.name
  json.latitude journey_checkin.lat
  json.longitude journey_checkin.lng
end
json.checked_in_at journey_checkin.created_at
