class RemoveGcsLegacyColumns < ActiveRecord::Migration[7.2]
  def change
    change_column_null :images, :user_id, false

    remove_column :images, :review_id, :bigint
    remove_column :users, :image_path, :string
    remove_column :maps, :image_url, :string
  end
end
