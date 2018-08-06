class AddUniqueIndexToUserImage < ActiveRecord::Migration[5.2]
  def change
    add_index :users, :image_path, unique: true
  end
end
