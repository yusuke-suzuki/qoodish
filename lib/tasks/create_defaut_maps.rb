# bin/rails runner lib/tasks/create_default_maps.rb
ActiveRecord::Base.transaction do
  User.all.each do |user|
    next if user.maps.exists?

    user.create_default_map
  end
end
