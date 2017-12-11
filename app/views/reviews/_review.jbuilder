json.id review.id
json.place_id review.place_id_val
json.author do
  json.name review.user.name
  json.profile_image_url review.user.image_url
end
json.comment review.comment
if review.image_url.present?
  json.image do
    json.url review.image_url
    json.file_name File.basename(CGI.unescape(review.image_url))
  end
end
json.spot do
  json.image_url review.spot.image_url.present? ? review.spot.image_url : ENV['SUBSTITUTE_URL']
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
