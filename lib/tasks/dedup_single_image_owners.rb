# bin/rails runner lib/tasks/dedup_single_image_owners.rb
#
# Removes the extra images held by maps and users, which show a single image.
# backfill_polymorphic_images could attach a legacy image to an owner whose
# image had already been replaced through the new upload flow, leaving two rows
# behind. Only the oldest image is ever rendered, so the later rows are dropped
# and the ones stored on Cloudflare go with them.
#
# Set DRY_RUN=1 to log what would be dropped without touching anything. Run it
# that way first: an environment with nothing to clean up reports 0.

dry_run = ActiveModel::Type::Boolean.new.cast(ENV.fetch('DRY_RUN', nil)).present?
found = 0

%w[Map User].each do |imageable_type|
  Image
    .where(imageable_type: imageable_type)
    .group(:imageable_id)
    .having('COUNT(*) > 1')
    .pluck(:imageable_id)
    .each do |imageable_id|
      extra_ids = Image
                  .where(imageable_type: imageable_type, imageable_id: imageable_id)
                  .order(:id)
                  .offset(1)
                  .pluck(:id)

      found += extra_ids.size

      if dry_run
        Rails.logger.info("#{imageable_type} #{imageable_id}: would drop images #{extra_ids.join(', ')}")
      else
        Image.where(id: extra_ids).each(&:destroy!)
      end
    end
end

Rails.logger.info("Dedup complete: #{dry_run ? 'would remove' : 'removed'} #{found} extra images")
