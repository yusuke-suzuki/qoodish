class AddCheckedInAtToJourneyCheckins < ActiveRecord::Migration[7.2]
  def change
    add_column :journey_checkins, :checked_in_at, :datetime
  end
end
