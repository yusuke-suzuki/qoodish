class RemovePlaceIdFromReviews < ActiveRecord::Migration[6.0]
  def change
    remove_column :reviews, :place_id_val, :string
  end
end
