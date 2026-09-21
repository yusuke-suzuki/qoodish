class CreateJournalRevisions < ActiveRecord::Migration[8.1]
  def change
    create_table :journal_revisions do |t|
      t.references :journal, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.string :description

      t.timestamps

      t.index %i[journal_id id]
    end
  end
end
