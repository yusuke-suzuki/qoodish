class CreateInappropriateContents < ActiveRecord::Migration[5.1]
  def change
    create_table :inappropriate_contents do |t|
      t.integer :user_id, index: true, foreign_key: true, null: false
      t.integer :content_id_val, null: false
      t.string :content_type, null: false
      t.integer :reason_id_val, null: false

      t.timestamps
    end
  end
end
