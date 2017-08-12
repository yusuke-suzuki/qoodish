json.id review.id
json.place_id review.place_id_val
json.author do
  json.name review.user.name
  json.profile_image_url review.user.image_url
end
json.comment review.comment
json.image do
  json.custom review.image_url.present?
  json.url review.image_url.present? ? review.image_url : ENV['SUBSTITUTE_URL']
  json.file_name review.image_url.present? ? File.basename(URI.decode(review.image_url)) : ''
end
json.spot do
  json.place_id review.spot.place_id
  json.name review.spot.name
  json.lat review.spot.lat
  json.lng review.spot.lng
  json.formatted_address review.spot.formatted_address
end
json.map_id review.map_id
json.map_name review.map.name
json.editable current_user.author?(review)
json.created_at review.created_at
json.updated_at review.updated_at
