# bin/rails runner lib/tasks/migrate_images_to_cloudflare.rb

migrated = 0
failed = 0

Image.where.not('url LIKE ?', "%#{Cloudflare::Images::DELIVERY_HOST}%").find_each do |image|
  new_url = Cloudflare::Images.new.upload_from_url(image.url)

  if new_url.blank?
    failed += 1
    Rails.logger.error("Failed to migrate image #{image.id}: empty variant URL")
    next
  end

  image.update_columns(url: new_url, updated_at: Time.current)
  migrated += 1
  Rails.logger.info("Migrated image #{image.id}: -> #{new_url}")
rescue StandardError => e
  failed += 1
  Rails.logger.error("Failed to migrate image #{image.id}: #{e.message}")
end

Rails.logger.info("Migration complete: #{migrated} migrated, #{failed} failed")
