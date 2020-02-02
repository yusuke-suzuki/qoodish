json.title @spot.name
json.description @spot.formatted_address
json.image_url @spot.review.images.exists? ? @spot.thumbnail_url('800x800') : ENV['OGP_IMAGE_URL']
