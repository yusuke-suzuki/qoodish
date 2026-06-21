class CreateBookmarks < ActiveRecord::Migration[7.2]
  def change
    create_table :bookmarks do |t|
      t.references :map, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps

      t.index %i[map_id user_id], unique: true
    end
  end
end
