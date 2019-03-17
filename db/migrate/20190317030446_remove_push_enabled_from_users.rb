class RemovePushEnabledFromUsers < ActiveRecord::Migration[6.0]
  def change
    remove_column :users, :push_enabled, :boolean
  end
end
