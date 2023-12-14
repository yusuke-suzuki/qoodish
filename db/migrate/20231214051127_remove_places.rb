class RemovePlaces < ActiveRecord::Migration[6.1]
  def change
    remove_foreign_key :spots, :places

    drop_table :spots
    drop_table :place_details
    drop_table :places
  end
end
