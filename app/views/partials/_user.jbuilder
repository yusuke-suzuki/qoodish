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
  user.web_push_preferences.each do |preference, enabled|
    json.set! preference, enabled
  end
end
