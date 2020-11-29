class RemovePlaceDetailsFromPlaces < ActiveRecord::Migration[6.0]
  def change
    remove_column :places, :name
    remove_column :places, :lat
    remove_column :places, :lng
    remove_column :places, :formatted_address
    remove_column :places, :opening_hours
    remove_column :places, :url
    remove_column :places, :lost
  end
end
