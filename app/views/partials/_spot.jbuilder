json.place_id spot.place_id_val
json.name spot.name
json.lat spot.lat
json.lng spot.lng
json.formatted_address spot.formatted_address
json.url spot.url
json.opening_hours spot.opening_hours
json.thumbnail_url spot.thumbnail_url
json.thumbnail_url_400 spot.thumbnail_url('400x400')
json.thumbnail_url_800 spot.thumbnail_url('800x800')
json.reviews spot.reviews, partial: 'partials/review', as: :review
