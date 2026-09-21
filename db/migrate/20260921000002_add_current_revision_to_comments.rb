class AddCurrentRevisionToComments < ActiveRecord::Migration[8.1]
  def change
    add_reference :comments, :current_revision, foreign_key: { to_table: :comment_revisions }
  end
end
