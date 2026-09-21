class AddCurrentRevisionToUsers < ActiveRecord::Migration[8.1]
  def change
    add_reference :users, :current_revision, foreign_key: { to_table: :user_revisions }
  end
end
