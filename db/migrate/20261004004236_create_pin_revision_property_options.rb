class CreatePinRevisionPropertyOptions < ActiveRecord::Migration[8.1]
  def change
    create_table :pin_revision_property_options do |t|
      t.references :pin_revision, null: false, foreign_key: true
      t.references :pin_property_option, null: false, foreign_key: true

      t.timestamps

      t.index %i[pin_revision_id pin_property_option_id], unique: true
    end
  end
end
