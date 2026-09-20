# rails runner lib/tasks/backfill_user_images.rb
#
# Written against the columns rather than the associations, so it can run on the
# revision serving traffic before this change is released.
class BackfillUserImages
  def run
    User.where(image_id: nil).find_each { |user| backfill(user) }
  end

  private

  def backfill(user)
    image_id = Image
               .where(imageable_type: User.name, imageable_id: user.id)
               .order(:id)
               .pick(:id)

    return if image_id.nil?

    user.update_column(:image_id, image_id)

    puts "[Backfill] User #{user.id}: image #{image_id}"
  end
end

runner = BackfillUserImages.new
runner.run
