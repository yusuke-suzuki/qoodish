json.title @spot.name
json.description @spot.formatted_address
json.image_url @spot.image_url.present? ? @spot.image_url : ENV['SUBSTITUTE_URL']
