json.id pin.id
json.name pin.name
json.latitude pin.lat
json.longitude pin.lng
json.author do
  json.id pin.user.id
  json.name pin.user.name
  json.image pin.user.image_variants
  json.image_url pin.user.image_url
end
json.comment pin.comment
json.comments pin.comments do |comment|
  json.id comment.id
  json.pin_id pin.id
  json.review_id pin.id
  json.author do
    json.id comment.user.id
    json.name comment.user.name
    json.image comment.user.image_variants
    json.image_url comment.user.image_url
  end
  json.body comment.body
  json.created_at comment.created_at
  json.updated_at comment.updated_at
end
json.images pin.images do |image|
  variants = image.variants
  json.id image.id
  json.url image.url
  json.avatar variants[:avatar]
  json.card variants[:card]
  json.hero variants[:hero]
  json.ogp variants[:ogp]
end
json.map do
  json.id pin.map_id
  json.name pin.map.name
  json.private pin.map.private
end
json.created_at pin.created_at
json.updated_at pin.updated_at
