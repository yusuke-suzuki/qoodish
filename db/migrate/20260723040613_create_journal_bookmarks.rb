class CreateJournalBookmarks < ActiveRecord::Migration[7.2]
  def change
    create_table :journal_bookmarks do |t|
      t.references :journal, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps

      t.index %i[journal_id user_id], unique: true
    end
  end
end
