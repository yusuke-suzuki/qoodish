namespace :images do
  desc 'Destroy images, along with their Cloudflare copies, that no record has referenced for a day since upload'
  task destroy_unattached: :environment do
    destroyed = Image.unattached.where(created_at: ...1.day.ago).find_each.map(&:destroy!)
    Rails.logger.info("Destroyed #{destroyed.size} unattached images")
  end
end
