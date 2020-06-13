class CreatePlaces < ActiveRecord::Migration[6.0]
  def change
    create_table :places do |t|
      t.string :place_id_val, null: false, index: { unique: true }

      t.timestamps
    end
  end
end
