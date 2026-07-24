class AddMapFeaturesToChapters < ActiveRecord::Migration[7.2]
  def change
    add_column :chapters, :map_features, :json, null: false
  end
end
