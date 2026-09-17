class CreateReports < ActiveRecord::Migration[8.1]
  def change
    create_table :reports do |t|
      t.references :moderatable, polymorphic: true, null: false
      t.references :reporter, foreign_key: { to_table: :users }
      t.string :reporter_email
      t.string :locale, null: false
      t.string :category, null: false
      t.text :details
      t.text :evidence_url
      t.text :content_snapshot
      t.bigint :reported_revision_id
      t.datetime :created_at, null: false
    end

    add_index :reports, %i[reporter_id moderatable_type moderatable_id], unique: true,
                        name: 'index_reports_on_reporter_and_moderatable'
    add_index :reports, %i[reporter_email moderatable_type moderatable_id], unique: true,
                        name: 'index_reports_on_reporter_email_and_moderatable'
  end
end
