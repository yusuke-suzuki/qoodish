class CreateUserRevisions < ActiveRecord::Migration[8.1]
  def change
    create_table :user_revisions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :biography

      t.timestamps

      t.index %i[user_id id]
    end
  end
end
