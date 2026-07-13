class CreateJourneyCheckins < ActiveRecord::Migration[7.2]
  def change
    create_table :journey_checkins do |t|
      t.references :journey, null: false, index: false, foreign_key: true
      t.references :review, foreign_key: true
      t.string :name, null: false
      t.decimal :latitude, precision: 16, scale: 6, null: false
      t.decimal :longitude, precision: 16, scale: 6, null: false

      t.timestamps

      t.index %i[journey_id review_id], unique: true
    end
  end
end
