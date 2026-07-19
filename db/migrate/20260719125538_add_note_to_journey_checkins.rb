class AddNoteToJourneyCheckins < ActiveRecord::Migration[7.2]
  def change
    add_column :journey_checkins, :note, :text
  end
end
