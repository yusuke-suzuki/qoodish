class AddCurrentRevisionToChapters < ActiveRecord::Migration[8.1]
  def change
    add_reference :chapters, :current_revision, foreign_key: { to_table: :chapter_revisions }
  end
end
