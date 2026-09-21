# bin/rails runner lib/tasks/audit_legacy_image_attachments.rb
#
# Reports what would be lost by dropping images.imageable_id and
# imageable_type. Reads nothing through the models, so it keeps working once
# the columns are ignored. It writes nothing.
#
# Two counts must both read 0 before the drop migration ships:
#
#   - a record with no current revision still answers for its images through
#     the legacy column, so it would come back holding none.
#   - a legacy attachment no revision carries is an image the record shows
#     today and would stop showing.
#
# Only the four models whose revisions carry images are counted. An avatar is
# not: it moved to users.image_id, and the attachment a replaced one leaves
# behind points at an image nothing renders.
class AuditLegacyImageAttachments
  REVISABLE_TABLES = %w[
    chapters
    journey_checkins
    maps
    pins
  ].freeze

  REVISION_IMAGE_TABLES = %w[
    chapter_revision_images
    journey_checkin_revision_images
    map_revision_images
    pin_revision_images
  ].freeze

  def run
    unrevised = REVISABLE_TABLES.sum { |table| report_unrevised(table) }
    uncarried = report_uncarried

    puts "[Audit] records without a revision: #{unrevised}"
    puts "[Audit] legacy attachments no revision carries: #{uncarried}"
    puts "[Audit] #{(unrevised + uncarried).zero? ? 'safe to drop' : 'NOT safe to drop'}"
  end

  private

  def report_unrevised(table)
    count = count_of("SELECT COUNT(*) FROM #{table} WHERE current_revision_id IS NULL")
    puts "[Audit] #{table}: #{count} without a revision" if count.positive?
    count
  end

  def report_uncarried
    carried = REVISION_IMAGE_TABLES.map { |table| "SELECT image_id FROM #{table}" }.join(' UNION ')

    count_of(<<~SQL.squish)
      SELECT COUNT(*) FROM images
      WHERE imageable_id IS NOT NULL
        AND imageable_type <> 'User'
        AND id NOT IN (#{carried})
    SQL
  end

  def count_of(sql)
    ActiveRecord::Base.connection.select_value(sql).to_i
  end
end

runner = AuditLegacyImageAttachments.new
runner.run
