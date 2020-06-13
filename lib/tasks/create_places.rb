class CreatePlaces
  def run
    ActiveRecord::Base.transaction do
      Spot.all.each do |spot|
        if spot.reviews.blank?
          spot.destroy!
          next
        end

        next if spot.place.present?

        place = Place.find_or_create_by!(
          place_id_val: spot.place_id_val
        )

        spot.update!(place: place)
      end
    end
  end
end

runner = CreatePlaces.new
runner.run
