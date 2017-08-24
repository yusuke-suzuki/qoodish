json.title "#{@review.spot.name} - #{@review.map.name}"
json.description @review.comment
json.image_url @review.image_url.present? ? @review.image_url : ENV['SUBSTITUTE_URL']
