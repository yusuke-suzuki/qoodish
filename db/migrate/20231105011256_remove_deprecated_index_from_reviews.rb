class RemoveDeprecatedIndexFromReviews < ActiveRecord::Migration[6.1]
  def change
    remove_foreign_key :reviews, :spots

    remove_index :reviews, column: %i[spot_id map_id user_id]
  end
end
