json.title @map.name
json.description @map.description
json.image_url @map.reviews.exists? && reviews[0].image_url.present? ? reviews[0].image_url : ENV['OGP_IMAGE_URL']
