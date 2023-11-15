class RemoveNotNullConstraintsFromReviews < ActiveRecord::Migration[6.1]
  def change
    change_column_null(:reviews, :spot_id, true)
  end
end
