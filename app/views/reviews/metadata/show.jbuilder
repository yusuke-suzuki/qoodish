json.title "#{@review.spot.name} - #{@review.map.name}"
json.description @review.comment
json.image_url @review.images.exists? ? @review.thumbnail_url('800x800') : ENV['OGP_IMAGE_URL']
