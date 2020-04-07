class AddImageUrlToMaps < ActiveRecord::Migration[6.0]
  def change
    add_column :maps, :image_url, :string
  end
end
