class CreateJourneyCheckinRevisions < ActiveRecord::Migration[8.1]
  def change
    create_table :journey_checkin_revisions do |t|
      t.references :journey_checkin, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :note
      t.datetime :checked_in_at, null: false
      t.string :status, null: false, default: 'recorded'

      t.timestamps

      t.index %i[journey_checkin_id id]
    end
  end
end
