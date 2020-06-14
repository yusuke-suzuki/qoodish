class RemoveIndexPlaceIdFromReviews < ActiveRecord::Migration[6.0]
  def change
    remove_index :reviews, name: 'index_reviews_on_place_id_val_and_map_id_and_user_id'
    remove_index :reviews, name: 'index_reviews_on_place_id_val'
  end
end
