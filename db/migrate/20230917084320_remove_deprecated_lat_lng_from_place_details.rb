class RemoveDeprecatedLatLngFromPlaceDetails < ActiveRecord::Migration[6.1]
  def change
    remove_column :place_details, :lat
    remove_column :place_details, :lng
  end
end
