json.id user.id
json.uid user.uid
json.email user.email
json.name user.name
json.biography user.biography
json.image_url user.image_path
json.thumbnail_url user.thumbnail_url
json.file_name user.image_name
json.maps_count user.maps.count
json.following_maps_count user.follow_count
json.reviews_count user.reviews.count
json.likes_count user.votes.count
json.push_notification do
  json.followed user.push_notification ? user.push_notification.followed : false
  json.invited user.push_notification ? user.push_notification.invited : false
  json.liked user.push_notification ? user.push_notification.liked : false
  json.comment user.push_notification ? user.push_notification.comment : false
end
