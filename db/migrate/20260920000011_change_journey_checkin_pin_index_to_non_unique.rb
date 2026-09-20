class ChangeJourneyCheckinPinIndexToNonUnique < ActiveRecord::Migration[8.1]
  def change
    remove_index :journey_checkins, %i[journey_id pin_id], unique: true
    add_index :journey_checkins, %i[journey_id pin_id]
  end
end
