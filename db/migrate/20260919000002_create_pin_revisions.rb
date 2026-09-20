class CreatePinRevisions < ActiveRecord::Migration[8.1]
  def change
    create_table :pin_revisions do |t|
      t.references :pin, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :name, null: false
      t.text :comment, null: false
      t.decimal :latitude, precision: 16, scale: 6, null: false
      t.decimal :longitude, precision: 16, scale: 6, null: false
      t.string :status, null: false, default: 'published'

      t.timestamps

      t.index %i[pin_id id]
    end
  end
end
