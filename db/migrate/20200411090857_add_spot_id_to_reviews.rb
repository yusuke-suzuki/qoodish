class AddSpotIdToReviews < ActiveRecord::Migration[6.0]
  def change
    add_column :reviews, :spot_id, :bigint, null: false, index: { unique: true }
  end
end
