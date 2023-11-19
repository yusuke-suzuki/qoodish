class AddLatLngToMaps < ActiveRecord::Migration[6.1]
  def change
    add_column :maps, :latitude, :decimal, precision: 16, scale: 6, null: false, default: 0
    add_column :maps, :longitude, :decimal, precision: 16, scale: 6, null: false, default: 0
  end
end
