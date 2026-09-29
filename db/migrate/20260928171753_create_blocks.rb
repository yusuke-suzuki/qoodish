class CreateBlocks < ActiveRecord::Migration[8.1]
  def change
    create_table :blocks do |t|
      t.references :blocker, null: false, foreign_key: { to_table: :users }, index: false
      t.references :blocked, null: false, foreign_key: { to_table: :users }
      t.datetime :created_at, null: false
    end
    add_index :blocks, %i[blocker_id blocked_id]
  end
end
