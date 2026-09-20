class AllowNullAuthorOnMapRevisions < ActiveRecord::Migration[8.1]
  def change
    change_column_null :map_revisions, :user_id, true
  end
end
