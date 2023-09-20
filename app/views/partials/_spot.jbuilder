json.id spot.id
json.map_id spot.map_id
json.place_id spot.place.place_id_val
json.name spot.place.name
json.lat spot.place.lat
json.lng spot.place.lng
json.formatted_address spot.place.formatted_address
json.url spot.place.url
json.opening_hours spot.place.opening_hours
json.thumbnail_url spot.thumbnail_url
json.thumbnail_url_400 spot.thumbnail_url('400x400')
json.thumbnail_url_800 spot.thumbnail_url('800x800')
json.reviews_count spot.reviews.size
json.reviews spot.reviews, partial: 'partials/review', as: :review
