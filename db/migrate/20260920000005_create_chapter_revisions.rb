class CreateChapterRevisions < ActiveRecord::Migration[8.1]
  def change
    create_table :chapter_revisions do |t|
      t.references :chapter, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.json :content, null: false
      t.json :map_features, null: false
      t.string :status, null: false, default: 'draft'

      t.timestamps

      t.index %i[chapter_id id]
    end
  end
end
