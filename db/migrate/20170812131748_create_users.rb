class CreateUsers < ActiveRecord::Migration[5.1]
  def change
    create_table :users do |t|
      t.string :name
      t.string :email
      t.string :uid, null: false
      t.string :provider, null: false
      t.string :provider_uid, null: false
      t.string :provider_token
      t.string :image_path

      t.timestamps
    end
    add_index :users, :uid
    add_index :users, [:provider, :provider_uid], unique: true
  end
end
