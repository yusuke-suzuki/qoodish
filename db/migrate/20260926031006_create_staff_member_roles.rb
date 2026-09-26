class CreateStaffMemberRoles < ActiveRecord::Migration[8.1]
  def change
    create_table :staff_member_roles do |t|
      t.references :staff_member, null: false, foreign_key: true, index: false
      t.references :role, null: false, foreign_key: true

      t.timestamps
    end
    add_index :staff_member_roles, %i[staff_member_id role_id], unique: true
  end
end
