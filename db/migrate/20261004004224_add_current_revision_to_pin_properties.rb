class AddCurrentRevisionToPinProperties < ActiveRecord::Migration[8.1]
  def change
    add_reference :pin_properties, :current_revision, foreign_key: { to_table: :pin_property_revisions, on_delete: :nullify }
  end
end
