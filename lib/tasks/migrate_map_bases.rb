# rails runner lib/tasks/migrate_map_bases.rb
class MigrateMapBases
  def run
    Map.all.each do |map|
      next if map.base_id_val.blank?

      puts "[Migrate] Start processing Map: #{map.id}"

      place_detail = PlaceDetail.find_by(
        place_id_val: map.base_id_val,
        locale: :ja
      )

      if place_detail.blank? || place_detail.latitude.blank? || place_detail.longitude.blank? || place_detail.name.blank?
        puts "[Migrate] PlaceDetail not found: #{map.base_id_val}"
        next
      end

      map.latitude = place_detail.latitude.to_f
      map.longitude = place_detail.longitude.to_f
      map.save!

      puts map.attributes

      puts "[Migrate] Finish processing Map: #{map.id}"
    end
  end
end

runner = MigrateMapBases.new
runner.run
