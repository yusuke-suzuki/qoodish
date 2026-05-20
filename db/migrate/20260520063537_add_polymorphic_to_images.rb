class AddPolymorphicToImages < ActiveRecord::Migration[7.2]
  def change
    add_reference :images, :user, foreign_key: true, null: true
    add_reference :images, :imageable, polymorphic: true, null: true
    change_column_null :images, :review_id, true
  end
end
