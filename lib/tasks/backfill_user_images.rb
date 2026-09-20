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

    # The second run happens while the released version is serving, so an
    # avatar can be chosen between the select above and this write.
    claimed = User.where(id: user.id, image_id: nil).update_all(image_id: image_id)

    return if claimed.zero?

    puts "[Backfill] User #{user.id}: image #{image_id}"
  end
end

runner = BackfillUserImages.new
runner.run
