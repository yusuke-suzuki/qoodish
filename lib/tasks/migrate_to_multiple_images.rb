# bin/rails runner lib/tasks/migrate_to_multiple_images.rb

ActiveRecord::Base.transaction do
  Review.all.each do |review|
    next if review.images.present?
    next if review.image_url.blank?

    review.images.create!(
      url: review.image_url
    )
    sleep(1)
  end
end
