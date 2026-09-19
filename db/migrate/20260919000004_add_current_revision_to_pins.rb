class AddCurrentRevisionToPins < ActiveRecord::Migration[8.1]
  def change
    add_reference :pins, :current_revision, foreign_key: { to_table: :pin_revisions }
    add_column :pins, :status, :integer, null: false, default: 0

    add_index :pins, %i[status created_at]
  end
end
