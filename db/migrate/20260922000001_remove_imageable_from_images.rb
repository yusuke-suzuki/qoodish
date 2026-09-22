class RemoveImageableFromImages < ActiveRecord::Migration[8.1]
  def change
    remove_index :images, %i[imageable_type imageable_id], name: 'index_images_on_imageable'
    remove_column :images, :imageable_id, :bigint
    remove_column :images, :imageable_type, :string
  end
end
