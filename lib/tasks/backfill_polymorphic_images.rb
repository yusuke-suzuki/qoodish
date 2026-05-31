# bin/rails runner lib/tasks/backfill_polymorphic_images.rb
#
# Populates the polymorphic columns added by 20260520063537_add_polymorphic_to_images.
# Run once after the migration; the follow-up migration that tightens NOT NULL and
# drops the legacy columns assumes this task has completed.

# Re-enable deprecated columns ignored at the model level so this task can read
# them. Read the legacy columns via [] (e.g. map[:image_url]) rather than the
# accessor: Map#image_url is redefined to read the new association and returns
# '' before the Image rows exist, which would silently skip every map.
[User, Map, Image].each do |model|
  model.ignored_columns = []
  model.reset_column_information
end

rewired = 0
Image.where(imageable_id: nil).where.not(review_id: nil).find_each do |image|
  review = Review.find_by(id: image.review_id)
  next unless review

  image.update_columns(
    user_id: review.user_id,
    imageable_id: review.id,
    imageable_type: 'Review'
  )
  rewired += 1
end

skipped = 0

user_avatars = 0
User.where.not(image_path: [nil, '']).find_each do |user|
  legacy_url = user[:image_path]
  # The SQL filter only excludes NULL and empty strings; whitespace-only values
  # reach here and would fail Image's url presence/format validation.
  next if legacy_url.blank?
  next if Image.exists?(url: legacy_url)

  Image.create!(
    user_id: user.id,
    imageable_id: user.id,
    imageable_type: 'User',
    url: legacy_url
  )
  user_avatars += 1
rescue ActiveRecord::RecordInvalid => e
  Rails.logger.warn("Skipped user #{user.id} avatar backfill: #{e.message}")
  skipped += 1
end

map_thumbnails = 0
Map.where.not(image_url: [nil, '']).find_each do |map|
  legacy_url = map[:image_url]
  next if legacy_url.blank?
  next if Image.exists?(url: legacy_url)

  Image.create!(
    user_id: map.user_id,
    imageable_id: map.id,
    imageable_type: 'Map',
    url: legacy_url
  )
  map_thumbnails += 1
rescue ActiveRecord::RecordInvalid => e
  Rails.logger.warn("Skipped map #{map.id} thumbnail backfill: #{e.message}")
  skipped += 1
end

summary = "Backfill complete: #{rewired} rewired, #{user_avatars} user avatars, " \
          "#{map_thumbnails} map thumbnails, #{skipped} skipped"
Rails.logger.info(summary)
