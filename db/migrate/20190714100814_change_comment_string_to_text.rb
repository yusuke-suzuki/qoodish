class ChangeCommentStringToText < ActiveRecord::Migration[6.0]
  def change
    change_column :reviews, :comment, :text
  end
end
