json.place_id spot.place_id
json.name spot.name
json.lat spot.lat
json.lng spot.lng
json.formatted_address spot.formatted_address
json.image_url spot.image_url.present? ? spot.image_url : ENV['SUBSTITUTE_URL']
