class RemoveProviderFromUsers < ActiveRecord::Migration[5.2]
  def change
    remove_column :users, :provider, :string
    remove_column :users, :provider_uid, :string
    remove_column :users, :provider_token, :string
  end
end
