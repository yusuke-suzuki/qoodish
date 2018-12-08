class CreateComments < ActiveRecord::Migration[5.2]
  def change
    create_table :comments do |t|
      t.references :commentable, polymorphic: true, index: true, null: false
      t.references :user, index: true, null: false
      t.text :body, null: false
      t.timestamps
    end
  end
end
