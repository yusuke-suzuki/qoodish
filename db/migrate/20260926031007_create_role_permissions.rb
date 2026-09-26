class CreateRolePermissions < ActiveRecord::Migration[8.1]
  def change
    create_table :role_permissions do |t|
      t.references :role, null: false, foreign_key: true, index: false
      t.string :permission, null: false

      t.timestamps
    end
    add_index :role_permissions, %i[role_id permission], unique: true
  end
end
