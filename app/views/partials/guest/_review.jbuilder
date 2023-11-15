json.id review.id
json.name review.name
json.latitude review.lat
json.longitude review.lng
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
  json.created_at comment.created_at
end
json.images review.images do |image|
  json.id image.id
  json.url image.url
  json.thumbnail_url image.thumbnail_url
  json.thumbnail_url_400 image.thumbnail_url('400x400')
  json.thumbnail_url_800 image.thumbnail_url('800x800')
end
json.map do
  json.id review.map_id
  json.name review.map.name
  json.private review.map.private
end
json.created_at review.created_at
json.updated_at review.updated_at
