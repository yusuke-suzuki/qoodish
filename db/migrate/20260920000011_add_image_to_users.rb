class AddImageToUsers < ActiveRecord::Migration[8.1]
  def change
    add_reference :users, :image, foreign_key: { on_delete: :nullify }
  end
end
