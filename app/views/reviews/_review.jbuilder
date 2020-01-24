json.id review.id
json.place_id review.place_id_val
json.author do
  json.id review.user.id
  json.name review.user.name
  json.profile_image_url review.user.thumbnail_url
end
json.comment review.comment
json.comments review.comments do |comment|
  json.id comment.id
  json.review_id review.id
  json.author do
    json.id comment.user.id
    json.name comment.user.name
    json.profile_image_url comment.user.thumbnail_url
  end
  json.body comment.body
  json.editable current_user.author?(comment)
  json.liked current_user.liked?(comment)
  json.likes_count comment.votes.size
  json.created_at comment.created_at
end
if review.image_url.present?
  json.image do
    json.url review.image_url
    json.thumbnail_url review.thumbnail_url
    json.thumbnail_url_400 review.thumbnail_url('400x400')
    json.thumbnail_url_800 review.thumbnail_url('800x800')
  end
end
json.spot do
  json.image_url review.spot.image_url.present? ? review.spot.image_url : ENV['SUBSTITUTE_URL']
  json.place_id review.spot.place_id
  json.name review.spot.name
  json.lat review.spot.lat
  json.lng review.spot.lng
  json.formatted_address review.spot.formatted_address
  json.url review.spot.url
  json.opening_hours review.spot.opening_hours
end
json.map do
  json.id review.map_id
  json.name review.map.name
  json.private review.map.private
end
json.editable current_user.author?(review)
json.liked current_user.liked?(review)
json.likes_count review.votes.size
json.created_at review.created_at
json.updated_at review.updated_at
