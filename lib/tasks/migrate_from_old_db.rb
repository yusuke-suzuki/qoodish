# bin/rails runner lib/tasks/migrate_from_old_db.rb
ActiveRecord::Base.transaction do
  File.open('users.json') do |file|
    users_json = JSON.load(file)
    users_json.each do |json|
      uid = json['uid'] || 'dummy'
      User.create!(
        id: json['id'],
        name: json['name'],
        email: json['email'],
        uid: uid,
        image_path: json['image_path'],
        provider: json['provider'],
        provider_uid: json['provider_uid'],
        provider_token: json['token']
      )
    end
  end
  p 'Successfully migrated users!'

  File.open('maps.json') do |file|
    maps_json = JSON.load(file)
    maps_json.each do |json|
      Map.create!(
        id: json['id'],
        user_id: json['user_id'],
        name: json['name'],
        description: json['description'],
        private: json['private'],
        invitable: json['invitable'],
        shared: json['shared'],
        base_id_val: json['base_id_val'],
        base_name: json['base_name']
      )
    end
  end
  p 'Successfully migrated maps!'

  File.open('follows.json') do |file|
    follows_json = JSON.load(file)
    follows_json.each do |json|
      follower = User.find_by!(id: json['follower_id'])
      map = Map.find_by(id: json['followable_id'])
      next if map.blank?

      follower.follow(map)
    end
  end
  p 'Successfully migrated follows!'

  images_json = []
  File.open('images.json') do |file|
    images_json = JSON.load(file)
  end

  File.open('reviews.json') do |file|
    reviews_json = JSON.load(file)
    reviews_json.each do |json|
      review = Review.create!(
        id: json['id'],
        user_id: json['user_id'],
        comment: json['comment'],
        map_id: json['map_id'],
        place_id_val: json['place_id_val']
      )
      image = images_json.find { |image_json| image_json['review_id'] == review.id }
      review.update!(image_url: "https://s3-ap-northeast-1.amazonaws.com/qoodish/#{image['path']}") if image.present?
    end
  end
  p 'Successfully migrated reviews!'
end
