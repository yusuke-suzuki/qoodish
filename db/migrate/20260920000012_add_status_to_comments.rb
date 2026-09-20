class AddStatusToComments < ActiveRecord::Migration[8.1]
  def change
    add_column :comments, :status, :string, null: false, default: 'published'
  end
end
