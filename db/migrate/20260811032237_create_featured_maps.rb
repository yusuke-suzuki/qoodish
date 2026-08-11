class CreateFeaturedMaps < ActiveRecord::Migration[8.1]
  def change
    create_table :featured_maps do |t|
      t.references :map, null: false, foreign_key: true

      t.timestamps

      # The endpoint reads the newest entry, so the log is scanned in
      # created_at order rather than by map.
      t.index %i[created_at map_id]
    end
  end
end
