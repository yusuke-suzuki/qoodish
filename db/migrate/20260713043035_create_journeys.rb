class CreateJourneys < ActiveRecord::Migration[7.2]
  def change
    create_table :journeys do |t|
      t.references :user, null: false, index: false, foreign_key: true
      t.references :map, foreign_key: true
      t.datetime :started_at
      t.datetime :finished_at
      t.text :encoded_path, size: :medium

      t.timestamps

      t.index %i[user_id map_id finished_at]
    end
  end
end
