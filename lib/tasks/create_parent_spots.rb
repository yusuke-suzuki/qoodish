class CreateParentSpots
  def run
    reviews = Review.all
    reviews.each do |review|
      next if review.spot.present?

      ActiveRecord::Base.transaction do
        spot = Spot.find_or_create_by!(
          map: review.map,
          place_id_val: review.place_id_val
        )

        review.update!(spot: spot)
      end
    end
  end
end

runner = CreateParentSpots.new
runner.run
