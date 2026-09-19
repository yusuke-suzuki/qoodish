json.id journey_checkin.id
json.pin_id journey_checkin.pin_id
json.review_id journey_checkin.pin_id
json.spot do
  json.name journey_checkin.name
  json.latitude journey_checkin.lat
  json.longitude journey_checkin.lng
end
json.note journey_checkin.note
json.images journey_checkin.images do |image|
  variants = image.variants
  json.id image.id
  json.url image.url
  json.avatar variants[:avatar]
  json.card variants[:card]
  json.hero variants[:hero]
  json.ogp variants[:ogp]
end
json.checked_in_at journey_checkin.checked_in_at
