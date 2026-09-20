class CreateJourneyCheckinRevisionImages < ActiveRecord::Migration[8.1]
  def change
    create_table :journey_checkin_revision_images do |t|
      t.references :journey_checkin_revision, null: false, foreign_key: true
      t.references :image, null: false, foreign_key: true

      t.timestamps

      t.index %i[journey_checkin_revision_id image_id], unique: true, name: 'index_checkin_revision_images_on_revision_id_and_image_id'
    end
  end
end
