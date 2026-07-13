class CreateChapters < ActiveRecord::Migration[7.2]
  def change
    create_table :chapters do |t|
      t.references :user, null: false, index: false, foreign_key: true
      t.references :map, foreign_key: true
      t.references :journey, index: { unique: true }, foreign_key: true
      t.string :title, null: false
      t.string :status, default: 'draft', null: false
      t.json :content, null: false

      t.timestamps

      t.index %i[user_id status]
    end
  end
end
