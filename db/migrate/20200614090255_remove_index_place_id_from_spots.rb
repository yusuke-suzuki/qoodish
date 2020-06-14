class RemoveIndexPlaceIdFromSpots < ActiveRecord::Migration[6.0]
  def change
    remove_index :spots, name: 'index_spots_on_place_id_val_and_map_id'
    remove_index :spots, name: 'index_spots_on_place_id_val'
  end
end
