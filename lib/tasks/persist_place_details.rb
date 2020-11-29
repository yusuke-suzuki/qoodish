class PersistPlaceDetails
  def run
    ActiveRecord::Base.transaction do
      Place.all.each do |place|
        puts "Start processing #{place.id} (#{place.place_id_val})"

        if place.lost
          puts "#{place.id} (#{place.place_id_val}) has lost"
          next
        end

        if place.name.present?
          puts "#{place.id} (#{place.place_id_val}) already updated"
          next
        end

        place.update!

        puts "Finish processing #{place.id} (#{place.place_id_val})"
      rescue => e
        puts e
        next
      end
    end
  end
end

runner = PersistPlaceDetails.new
runner.run
