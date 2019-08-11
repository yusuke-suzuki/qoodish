json.id map.id
json.owner_id map.user.id
json.owner_name map.user.name
json.owner_image_url map.user.thumbnail_url
json.name map.name
json.description map.description
json.private map.private
json.base do
  json.place_id map.base.place_id
  json.name map.base.name
  json.lat map.base.lat
  json.lng map.base.lng
end
json.liked current_user.liked?(map)
json.likes_count map.votes.size
json.following current_user.following?(map)
json.followers_count map.follows.size
json.editable current_user.map_owner?(map)
json.postable current_user.postable?(map)
json.shared map.shared
json.invitable map.invitable
json.image_url map.image_url
json.thumbnail_url map.thumbnail_url
json.created_at map.created_at
json.updated_at map.updated_at
json.last_reported_at map.reviews.size > 0 ? map.reviews.last.created_at : nil
