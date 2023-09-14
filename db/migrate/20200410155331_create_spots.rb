class CreateSpots < ActiveRecord::Migration[6.0]
  def change
    create_table :spots do |t|
      t.references :map, null: false
      t.string :place_id_val, null: false

      t.timestamps
    end

    add_index :spots, %i[place_id_val map_id], unique: true
  end
end
