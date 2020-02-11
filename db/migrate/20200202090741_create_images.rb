class CreateImages < ActiveRecord::Migration[6.0]
  def change
    create_table :images do |t|
      t.references :review, null: false
      t.string :url, null: false, index: { unique: true }

      t.timestamps
    end
  end
end
