json.id map.id
json.owner_id map.user.id
json.owner_name map.user.name
json.owner_image_url map.user.thumbnail_url
json.name map.name
json.description map.description
json.private map.private
json.liked current_user.liked?(map)
json.likes_count map.voters.size
json.following current_user.following?(map)
json.followers_count map.followers.size
json.shared map.shared
json.invitable map.invitable
json.thumbnail_url map.image_url.present? ? map.thumbnail_url : ''
json.thumbnail_url_400 map.image_url.present? ? map.thumbnail_url('400x400') : ''
json.created_at map.created_at
json.updated_at map.updated_at
