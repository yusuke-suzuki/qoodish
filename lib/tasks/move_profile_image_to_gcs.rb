# bin/rails runner lib/tasks/move_profile_image_to_gcs.rb

require 'google/cloud'
require 'open-uri'

gcloud = Google::Cloud.new ENV['FIREBACE_PROJECT_ID'], './gcp-credentials.json'
storage = gcloud.storage
bucket = storage.bucket ENV['FIREBASE_IMAGE_BUCKET_NAME']

ActiveRecord::Base.transaction do
  User.all.each do |user|
    s3_image_url = user.image_image_url
    file_name = File.basename(s3_image_url)
    open(s3_image_url, 'rb') do |data|
      bucket.create_file(data, "profile/#{file_name}", { content_type: 'image/jpeg' })
    end
    file = bucket.file "profile/#{file_name}"
    download_url = "https://firebasestorage.googleapis.com/v0/b/#{ENV['FIREBASE_IMAGE_BUCKET_NAME']}/o/profile%2F#{file_name}?alt=media"
    user.update!(image_path: download_url)
  end
end
