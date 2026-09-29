class CreateUnblocks < ActiveRecord::Migration[8.1]
  def change
    create_table :unblocks do |t|
      t.references :block, null: false, foreign_key: { on_delete: :cascade }, index: { unique: true }
      t.datetime :created_at, null: false
    end
  end
end
