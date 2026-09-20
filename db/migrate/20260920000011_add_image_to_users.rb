class AddImageToUsers < ActiveRecord::Migration[8.1]
  def change
    add_reference :users, :image, foreign_key: true
  end
end
