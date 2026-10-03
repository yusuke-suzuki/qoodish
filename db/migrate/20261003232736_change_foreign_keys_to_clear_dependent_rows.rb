class ChangeForeignKeysToClearDependentRows < ActiveRecord::Migration[8.1]
  REVISABLE_TABLES = %i[chapters comments journals journey_checkins maps pins users].freeze

  USER_REFERENCES = {
    blocks: %i[blocker_id blocked_id],
    mutes: %i[muter_id muted_id]
  }.freeze

  def change
    REVISABLE_TABLES.each do |table|
      revisions = :"#{table.to_s.singularize}_revisions"

      remove_foreign_key table, revisions, column: :current_revision_id
      add_foreign_key table, revisions, column: :current_revision_id, on_delete: :nullify
    end

    USER_REFERENCES.each do |table, columns|
      columns.each do |column|
        remove_foreign_key table, :users, column: column
        add_foreign_key table, :users, column: column, on_delete: :cascade
      end
    end
  end
end
