class ChangeJourneyCheckinsCheckedInAtNull < ActiveRecord::Migration[7.2]
  def change
    change_column_null :journey_checkins, :checked_in_at, false
  end
end
