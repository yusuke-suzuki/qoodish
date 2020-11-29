class AddPlaceDetailsToPlaces < ActiveRecord::Migration[6.0]
  def change
    add_column :places, :name, :string, null: false
    add_column :places, :lat, :float, null: false
    add_column :places, :lng, :float, null: false
    add_column :places, :formatted_address, :string, null: false
    add_column :places, :url, :string
    add_column :places, :opening_hours, :text
    add_column :places, :lost, :boolean, default: false
  end
end
