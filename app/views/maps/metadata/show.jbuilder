json.title @map.name
json.description @map.description
json.image_url @map.reviews.present? @map.image_url : ENV['OGP_IMAGE_URL']
