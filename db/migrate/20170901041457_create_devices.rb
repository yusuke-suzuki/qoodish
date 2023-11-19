class CreateDevices < ActiveRecord::Migration[5.1]
  def change
    create_table :devices do |t|
      t.references :user, index: true, foreign_key: true, null: false
      t.string :registration_token, null: false

      t.timestamps
    end
    add_index :devices, :registration_token
    add_index :devices, %i[user_id registration_token], unique: true
  end
end
