class AddPlaceIdToSpots < ActiveRecord::Migration[6.0]
  def change
    add_column :spots, :place_id, :bigint, null: false

    add_index :spots, :place_id_val
  end
end
