class CreateStaffMembers < ActiveRecord::Migration[8.1]
  def change
    create_table :staff_members do |t|
      t.string :email, null: false
      t.datetime :revoked_at

      t.timestamps
    end
    add_index :staff_members, :email, unique: true
  end
end
