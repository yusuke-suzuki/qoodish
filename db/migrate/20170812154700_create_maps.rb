class CreateMaps < ActiveRecord::Migration[5.1]
  def change
    create_table :maps do |t|
      t.references :user, index: true, foreign_key: true, null: false
      t.string :name, null: false
      t.string :description, null: false
      t.boolean :private, default: true
      t.boolean :invitable, default: false
      t.boolean :shared, default: false
      t.string :base_id_val
      t.string :base_name

      t.timestamps
    end
  end
end
