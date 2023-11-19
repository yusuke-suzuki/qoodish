class CreatePlaces
  def run
    ActiveRecord::Base.transaction do
      Spot.all.each do |spot|
        puts "Start processing #{spot.id}"

        if spot.reviews.blank?
          puts "#{spot.id} has no reviews"
          spot.destroy!
          next
        end

        if spot.place.present?
          puts "#{spot.id} already has place"
          next
        end

        place = Place.find_or_create_by!(
          place_id_val: spot.place_id_val
        )

        spot.update!(place: place)

        puts "Finish processing #{spot.id}"
      rescue StandardError => e
        puts e
        next
      end
    end
  end
end

runner = CreatePlaces.new
runner.run
