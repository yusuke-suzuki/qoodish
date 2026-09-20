class AddCurrentRevisionToJourneyCheckins < ActiveRecord::Migration[8.1]
  def change
    add_reference :journey_checkins, :current_revision, foreign_key: { to_table: :journey_checkin_revisions }
    add_column :journey_checkins, :status, :string, null: false, default: 'recorded'
  end
end
