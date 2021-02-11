class AddLatLngToPlaceDetails < ActiveRecord::Migration[6.0]
  def change
    add_column :place_details, :latitude, :decimal, precision: 16, scale: 6, null: false
    add_column :place_details, :longitude, :decimal, precision: 16, scale: 6, null: false
  end
end
