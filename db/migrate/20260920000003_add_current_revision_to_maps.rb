class AddCurrentRevisionToMaps < ActiveRecord::Migration[8.1]
  def change
    add_reference :maps, :current_revision, foreign_key: { to_table: :map_revisions }
    add_column :maps, :status, :string, null: false, default: 'published'

    add_index :maps, %i[status created_at]
  end
end
