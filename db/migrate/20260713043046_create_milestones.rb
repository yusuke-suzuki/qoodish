class CreateMilestones < ActiveRecord::Migration[7.2]
  def change
    create_table :milestones do |t|
      t.references :journey, null: false, index: false, foreign_key: true
      t.references :review, foreign_key: true
      t.integer :position, null: false
      t.string :name, null: false
      t.decimal :latitude, precision: 16, scale: 6, null: false
      t.decimal :longitude, precision: 16, scale: 6, null: false

      t.timestamps

      t.index %i[journey_id review_id], unique: true
      t.index %i[journey_id position]
    end
  end
end
