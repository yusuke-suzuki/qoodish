# bin/rails runner lib/tasks/migrate_timestamp_from_old_db.rb
ActiveRecord::Base.transaction do
  File.open('maps.json') do |file|
    maps_json = JSON.load(file)
    maps_json.each do |json|
      map = Map.find_by(id: json['id'])
      next if map.blank?
      map.update!(
        created_at: json['created_at'],
        updated_at: json['updated_at']
      )
    end
  end
  p 'Successfully migrated maps!'

  File.open('reviews.json') do |file|
    reviews_json = JSON.load(file)
    reviews_json.each do |json|
      review = Review.find_by(id: json['id'])
      next if review.blank?
      review.update!(
        created_at: json['created_at'],
        updated_at: json['updated_at']
      )
    end
  end
  p 'Successfully migrated reviews!'
end
