class MigrateLatLngToDecimal
  def run
    ActiveRecord::Base.transaction do
      PlaceDetail.all.each do |place_detail|
        puts "Start processing #{place_detail.id}"

        place_detail.save!

        puts "Finish processing #{place_detail.id}"
      rescue => e
        puts e
        next
      end
    end
  end
end

runner = MigrateLatLngToDecimal.new
runner.run
