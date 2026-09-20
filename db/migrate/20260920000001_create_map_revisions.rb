class CreateMapRevisions < ActiveRecord::Migration[8.1]
  def change
    create_table :map_revisions do |t|
      t.references :map, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :description, null: false
      t.decimal :latitude, precision: 16, scale: 6, null: false
      t.decimal :longitude, precision: 16, scale: 6, null: false
      t.boolean :private, null: false, default: true
      t.string :status, null: false, default: 'published'

      t.timestamps

      t.index %i[map_id id]
    end
  end
end
