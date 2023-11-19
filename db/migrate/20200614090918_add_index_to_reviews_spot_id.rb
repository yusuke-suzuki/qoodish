class AddIndexToReviewsSpotId < ActiveRecord::Migration[6.0]
  def change
    add_index :reviews, %i[spot_id map_id user_id], unique: true
  end
end
