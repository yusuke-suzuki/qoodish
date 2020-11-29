class RemoveConstraintsFromPlaceDetails < ActiveRecord::Migration[6.0]
  def change
    change_column :place_details, :lat, :float, null: true
    change_column :place_details, :lng, :float, null: true
    change_column :place_details, :formatted_address, :string, null: true
  end
end
