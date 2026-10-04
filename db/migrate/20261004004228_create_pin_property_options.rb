class CreatePinPropertyOptions < ActiveRecord::Migration[8.1]
  def change
    create_table :pin_property_options do |t|
      t.references :pin_property, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :position, null: false, default: 0
      t.string :status, null: false, default: 'published'

      t.timestamps
    end
  end
end
