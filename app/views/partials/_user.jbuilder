json.id user.id
json.uid user.uid
json.name user.name
json.biography user.biography
json.image user.image_variants
json.image_url user.image_url
json.maps_count user.maps.published.count
json.bookmarked_maps_count user.bookmark_count
json.pins_count user.pins.published.count
json.reviews_count user.pins.published.count
json.push_notification do
  user.web_push_preferences.each do |preference, enabled|
    json.set! preference, enabled
  end
end
