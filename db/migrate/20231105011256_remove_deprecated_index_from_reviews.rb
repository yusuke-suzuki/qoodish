class RemoveDeprecatedIndexFromReviews < ActiveRecord::Migration[6.1]
  def change
    remove_index :reviews, column: %i[spot_id map_id user_id]

    remove_foreign_key :reviews, :spots
  end
end
