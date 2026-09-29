class CreateUnmutes < ActiveRecord::Migration[8.1]
  def change
    create_table :unmutes do |t|
      t.references :mute, null: false, foreign_key: { on_delete: :cascade }, index: { unique: true }
      t.datetime :created_at, null: false
    end
  end
end
