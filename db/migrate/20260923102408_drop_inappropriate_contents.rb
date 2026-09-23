class DropInappropriateContents < ActiveRecord::Migration[8.1]
  def change
    drop_table :inappropriate_contents do |t|
      t.integer :content_id_val, null: false
      t.string :content_type, null: false
      t.datetime :created_at, null: false
      t.integer :reason_id_val, null: false
      t.datetime :updated_at, null: false
      t.integer :user_id, null: false

      t.index :user_id
    end
  end
end
