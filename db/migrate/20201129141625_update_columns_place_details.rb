class UpdateColumnsPlaceDetails < ActiveRecord::Migration[6.0]
  def change
    change_column :place_details, :name, :text, null: true
    change_column :place_details, :formatted_address, :text, null: true
    change_column :place_details, :url, :text, null: true
  end
end
