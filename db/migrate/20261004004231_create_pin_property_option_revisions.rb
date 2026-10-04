class CreatePinPropertyOptionRevisions < ActiveRecord::Migration[8.1]
  def change
    create_table :pin_property_option_revisions do |t|
      t.references :pin_property_option, null: false, foreign_key: true
      t.references :user, foreign_key: { on_delete: :nullify }
      t.string :name, null: false
      t.integer :position, null: false
      t.string :status, null: false, default: 'published'

      t.timestamps

      t.index %i[pin_property_option_id id]
    end
  end
end
