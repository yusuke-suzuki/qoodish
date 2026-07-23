class CreateJournals < ActiveRecord::Migration[7.2]
  def change
    create_table :journals do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :title, null: false
      t.string :description

      t.timestamps
    end
  end
end
