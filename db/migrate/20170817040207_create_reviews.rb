class CreateReviews < ActiveRecord::Migration[5.1]
  def change
    create_table :reviews do |t|
      t.references :user, index: true, foreign_key: true, null: false
      t.references :map, index: true, foreign_key: true, null: false
      t.string :place_id_val, null: false
      t.string :comment, null: false
      t.string :image_url

      t.timestamps
    end
    add_index :reviews, :place_id_val
    add_index :reviews, [:place_id_val, :map_id, :user_id], unique: true
  end
end
