class AddLatLngToReviews < ActiveRecord::Migration[6.1]
  def change
    add_column :reviews, :latitude, :decimal, precision: 16, scale: 6, null: false
    add_column :reviews, :longitude, :decimal, precision: 16, scale: 6, null: false
    add_column :reviews, :name, :text, null: false

    remove_column :reviews, :image_url
  end
end
