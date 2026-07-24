json.id user.id
json.uid user.uid
json.name user.name
json.biography user.biography
json.image user.image_variants
json.image_url user.image_url
json.maps_count user.maps.count
json.bookmarked_maps_count user.bookmark_count
json.reviews_count user.reviews.count
json.push_notification do
  json.coauthor_invited user.push_notification ? user.push_notification.coauthor_invited : false
  json.liked user.push_notification ? user.push_notification.liked : false
  json.comment user.push_notification ? user.push_notification.comment : false
  json.bookmarked user.push_notification ? user.push_notification.bookmarked : false
end
