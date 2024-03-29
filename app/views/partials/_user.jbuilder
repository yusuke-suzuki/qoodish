json.id user.id
json.uid user.uid
json.name user.name
json.biography user.biography
json.image_url user.image_path
json.thumbnail_url user.thumbnail_url
json.thumbnail_url_400 user.thumbnail_url('400x400')
json.thumbnail_url_800 user.thumbnail_url('800x800')
json.maps_count user.maps.count
json.following_maps_count user.follow_count
json.reviews_count user.reviews.count
json.push_notification do
  json.followed user.push_notification ? user.push_notification.followed : false
  json.liked user.push_notification ? user.push_notification.liked : false
  json.comment user.push_notification ? user.push_notification.comment : false
end
