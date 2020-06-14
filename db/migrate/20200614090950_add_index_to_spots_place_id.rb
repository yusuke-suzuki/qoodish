class AddIndexToSpotsPlaceId < ActiveRecord::Migration[6.0]
  def change
    add_index :spots, [:place_id, :map_id], unique: true
  end
end
