# rails runner lib/tasks/update_images_to_new_bucket.rb

ActiveRecord::Base.transaction do
  Image.all.each do |image|
    url = "#{ENV['CLOUD_STORAGE_ENDPOINT']}/#{ENV['CLOUD_STORAGE_BUCKET_NAME']}/images/#{File.basename(image.file_name,
                                                                                                       image.ext)}#{image.ext}"
    image.update!(url: url)
    puts "Successfully updated ID: #{image.id}, URL: #{url}"
  end
end
