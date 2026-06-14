json.id review.id
json.name review.name
json.latitude review.lat
json.longitude review.lng
json.author do
  json.id review.user.id
  json.name review.user.name
  json.image review.user.image_variants
  json.image_url review.user.image_url
end
json.comment review.comment
json.comments review.comments do |comment|
  json.id comment.id
  json.review_id review.id
  json.author do
    json.id comment.user.id
    json.name comment.user.name
    json.image comment.user.image_variants
    json.image_url comment.user.image_url
  end
  json.body comment.body
  json.created_at comment.created_at
end
json.images review.images do |image|
  variants = image.variants
  json.id image.id
  json.url image.url
  json.avatar variants[:avatar]
  json.card variants[:card]
  json.hero variants[:hero]
  json.ogp variants[:ogp]
end
json.map do
  json.id review.map_id
  json.name review.map.name
  json.private review.map.private
end
json.created_at review.created_at
json.updated_at review.updated_at
