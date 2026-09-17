class AddFeedOrderIndexes < ActiveRecord::Migration[8.1]
  def change
    add_index :pins, :created_at
    add_index :chapters, %i[status created_at]
  end
end
