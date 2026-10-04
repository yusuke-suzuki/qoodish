class CreatePinProperties < ActiveRecord::Migration[8.1]
  def change
    create_table :pin_properties do |t|
      t.references :map, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :position, null: false, default: 0
      t.boolean :multiple, null: false, default: false
      t.string :status, null: false, default: 'published'

      t.timestamps
    end
  end
end
