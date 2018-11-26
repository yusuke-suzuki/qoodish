class AddPushEnabledToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :push_enabled, :boolean, default: false, null: false
  end
end
