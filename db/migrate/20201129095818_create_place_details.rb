class CreatePlaceDetails < ActiveRecord::Migration[6.0]
  def change
    create_table :place_details do |t|
      t.string :place_id_val, null: false
      t.integer :locale, null: false
      t.string :name
      t.float :lat, null: false
      t.float :lng, null: false
      t.string :formatted_address, null: false
      t.string :url
      t.text :opening_hours
      t.boolean :lost, null: false, default: false

      t.timestamps
    end

    add_index :place_details, %i[place_id_val locale], unique: true
  end
end
