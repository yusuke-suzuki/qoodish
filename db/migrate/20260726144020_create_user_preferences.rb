class CreateUserPreferences < ActiveRecord::Migration[7.2]
  def change
    create_table :user_preferences do |t|
      t.references :user, null: false, foreign_key: true
      t.json :web_push, null: false

      t.timestamps
    end
  end
end
