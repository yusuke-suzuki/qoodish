class CreateMapRevisionImages < ActiveRecord::Migration[8.1]
  def change
    create_table :map_revision_images do |t|
      t.references :map_revision, null: false, foreign_key: true
      t.references :image, null: false, foreign_key: true

      t.timestamps

      t.index %i[map_revision_id image_id], unique: true
    end
  end
end
