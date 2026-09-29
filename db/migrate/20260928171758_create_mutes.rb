class CreateMutes < ActiveRecord::Migration[8.1]
  def change
    create_table :mutes do |t|
      t.references :muter, null: false, foreign_key: { to_table: :users }, index: false
      t.references :muted, null: false, foreign_key: { to_table: :users }
      t.datetime :created_at, null: false
    end
    add_index :mutes, %i[muter_id muted_id]
  end
end
