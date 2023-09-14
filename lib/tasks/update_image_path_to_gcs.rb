# bin/rails runner lib/tasks/update_image_path_to_gcs.rb

ActiveRecord::Base.transaction do
  User.all.each do |user|
    next if user.image_path.blank?

    user.image_path = "#{ENV['CLOUD_STORAGE_ENDPOINT']}/#{ENV['CLOUD_STORAGE_BUCKET_NAME']}/profile/#{user.image_name.split('?')[0]}"
    user.save!
  end
  p 'Successfully updated users!'

  Review.all.each do |review|
    next if review.image_url.blank?

    review.image_url = "#{ENV['CLOUD_STORAGE_ENDPOINT']}/#{ENV['CLOUD_STORAGE_BUCKET_NAME']}/images/#{review.image_name.split('?')[0]}"
    review.save!
  end
  p 'Successfully updated reviews!'
end
