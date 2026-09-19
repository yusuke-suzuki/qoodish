class RenameReviewsToPins < ActiveRecord::Migration[8.1]
  def change
    rename_table :reviews, :pins
    rename_column :milestones, :review_id, :pin_id
    rename_column :journey_checkins, :review_id, :pin_id
  end
end
