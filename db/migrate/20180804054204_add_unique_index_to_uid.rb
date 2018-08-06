class AddUniqueIndexToUid < ActiveRecord::Migration[5.2]
  def change
    remove_index :users, :uid
    add_index :users, :uid, unique: true
  end
end
