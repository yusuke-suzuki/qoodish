class AddCurrentRevisionToPinPropertyOptions < ActiveRecord::Migration[8.1]
  def change
    add_reference :pin_property_options, :current_revision, foreign_key: { to_table: :pin_property_option_revisions, on_delete: :nullify }
  end
end
