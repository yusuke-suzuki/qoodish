json.id map.id
json.owner_id map.user.id
json.owner_name map.user.name
json.owner_image_url map.user.image_url
json.name map.name
json.description map.description
json.private map.private
json.base do
  json.place_id map.base.place_id
  json.name map.base.name
  json.lat map.base.lat
  json.lng map.base.lng
end
json.following current_user.following?(map)
json.editable current_user.map_owner?(map)
json.shared map.shared
json.invitable map.invitable
json.image_url map.reviews.exists? && map.reviews[0].image_url.present? ? map.reviews[0].image_url : ENV['SUBSTITUTE_URL']
json.created_at map.created_at
json.updated_at map.updated_at
