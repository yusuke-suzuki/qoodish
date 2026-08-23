# bin/rails runner lib/tasks/dedup_single_image_owners.rb
#
# Removes the extra images held by maps and users, which show a single image.
# backfill_polymorphic_images could attach a legacy image to an owner whose
# image had already been replaced through the new upload flow, leaving two rows
# behind. Only the oldest image is ever rendered, so the later rows are dropped
# and the ones stored on Cloudflare go with them.

removed = 0

%w[Map User].each do |imageable_type|
  Image
    .where(imageable_type: imageable_type)
    .group(:imageable_id)
    .having('COUNT(*) > 1')
    .pluck(:imageable_id)
    .each do |imageable_id|
      extras = Image
               .where(imageable_type: imageable_type, imageable_id: imageable_id)
               .order(:id)
               .offset(1)

      removed += extras.each(&:destroy!).size
    end
end

Rails.logger.info("Dedup complete: removed #{removed} extra images")
