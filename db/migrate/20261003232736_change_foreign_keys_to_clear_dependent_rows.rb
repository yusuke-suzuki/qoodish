class ChangeForeignKeysToClearDependentRows < ActiveRecord::Migration[8.1]
  FOREIGN_KEYS = [
    [:chapters, :chapter_revisions, :current_revision_id, 'fk_rails_1c8a18c6b0', :nullify],
    [:comments, :comment_revisions, :current_revision_id, 'fk_rails_598e499e12', :nullify],
    [:journals, :journal_revisions, :current_revision_id, 'fk_rails_d8345f1b83', :nullify],
    [:journey_checkins, :journey_checkin_revisions, :current_revision_id, 'fk_rails_4de318bcf3', :nullify],
    [:maps, :map_revisions, :current_revision_id, 'fk_rails_7fe7872f86', :nullify],
    [:pins, :pin_revisions, :current_revision_id, 'fk_rails_ae6e2f1f41', :nullify],
    [:users, :user_revisions, :current_revision_id, 'fk_rails_3674e37df0', :nullify],
    [:blocks, :users, :blocker_id, 'fk_rails_c0ad31bb25', :cascade],
    [:blocks, :users, :blocked_id, 'fk_rails_c7fbc30382', :cascade],
    [:mutes, :users, :muter_id, 'fk_rails_3169283784', :cascade],
    [:mutes, :users, :muted_id, 'fk_rails_2f059f5877', :cascade]
  ].freeze

  def change
    FOREIGN_KEYS.each do |table, to_table, column, current_name, on_delete|
      add_foreign_key table, to_table, column: column, on_delete: on_delete, name: "fk_#{table}_#{column}"
      remove_foreign_key table, to_table, column: column, name: current_name
    end
  end
end
