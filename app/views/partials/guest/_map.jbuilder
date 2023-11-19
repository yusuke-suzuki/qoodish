json.id map.id
json.owner do
  json.id map.user.id
  json.name map.user.name
  json.profile_image_url map.user.thumbnail_url
end
json.name map.name
json.description map.description
json.latitude map.lat
json.longitude map.lng
json.following false
json.editable false
json.postable false
json.private map.private
json.shared map.shared
json.invitable map.invitable
json.thumbnail_url map.image_url.present? ? map.thumbnail_url : ''
json.thumbnail_url_400 map.image_url.present? ? map.thumbnail_url('400x400') : ''
json.thumbnail_url_800 map.image_url.present? ? map.thumbnail_url('800x800') : ''
json.created_at map.created_at
json.updated_at map.updated_at
