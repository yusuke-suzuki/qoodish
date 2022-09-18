class AddForeignKeys < ActiveRecord::Migration[6.1]
  def change
    add_foreign_key :reviews, :spots
    add_foreign_key :images, :reviews
    add_foreign_key :spots, :places
  end
end
