# rails runner lib/tasks/migrate_reviews_to_pins.rb
class MigrateReviewsToPins
  def run
    Review.all.each do |review|
      puts "[Migrate] Start processing Review: #{review.id}"

      spot = Spot.find(review.spot_id)

      place_detail = PlaceDetail.find_by(
        place_id_val: spot.place.place_id_val,
        locale: :ja
      )

      if place_detail.blank? || place_detail.latitude.blank? || place_detail.longitude.blank? || place_detail.name.blank?
        puts "[Migrate] PlaceDetail not found: #{spot.place.place_id_val}"
        puts review.attributes
        review.destroy!
        next
      end

      review.latitude = place_detail.latitude.to_f
      review.longitude = place_detail.longitude.to_f
      review.name = place_detail.name
      review.save!

      puts review.attributes

      puts "[Migrate] Finish processing Review: #{review.id}"
    end
  end
end

runner = MigrateReviewsToPins.new
runner.run
