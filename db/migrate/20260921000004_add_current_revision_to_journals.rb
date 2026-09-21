class AddCurrentRevisionToJournals < ActiveRecord::Migration[8.1]
  def change
    add_reference :journals, :current_revision, foreign_key: { to_table: :journal_revisions }
  end
end
