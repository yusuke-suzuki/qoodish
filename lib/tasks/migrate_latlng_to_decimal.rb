class MigrateLatLngToDecimal
  def run
    PlaceDetail.all.each do |place_detail|
      puts "[Migrate] Start processing #{place_detail.id}"
      puts "[Migrate] before lat: #{place_detail.latitude}, lng: #{place_detail.longitude}"

      place_detail.save!

      puts "[Migrate] after lat: #{place_detail.latitude}, lng: #{place_detail.longitude}"
      puts "[Migrate] Finish processing #{place_detail.id}"
    end
  end
end

runner = MigrateLatLngToDecimal.new
runner.run
