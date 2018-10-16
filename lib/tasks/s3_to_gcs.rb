# bin/rails runner lib/tasks/s3_to_gcs.rb

require 'google/cloud'
require 'open-uri'

gcloud = Google::Cloud.new ENV['FIREBASE_PROJECT_ID'], './gcp-credentials.json'
storage = gcloud.storage
bucket = storage.bucket ENV['FIREBASE_IMAGE_BUCKET_NAME']

target_reviews = Review.where.like(image_url: '%aws%')
target_reviews.each do |review|
  s3_image_url = review.image_url
  file_name = File.basename(s3_image_url)
  open(s3_image_url, 'rb') do |data|
    bucket.create_file(data, "images/#{file_name}", { content_type: 'image/jpeg' })
  end
  file = bucket.file "images/#{file_name}"
  download_url = "https://firebasestorage.googleapis.com/v0/b/#{ENV['FIREBASE_IMAGE_BUCKET_NAME']}/o/images%2F#{file_name}?alt=media"
  review.update!(image_url: download_url)
end
