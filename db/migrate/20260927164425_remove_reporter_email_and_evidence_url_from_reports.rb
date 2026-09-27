class RemoveReporterEmailAndEvidenceUrlFromReports < ActiveRecord::Migration[8.1]
  def change
    remove_index :reports, %i[reporter_email moderatable_type moderatable_id],
                 name: 'index_reports_on_reporter_email_and_moderatable', unique: true
    remove_column :reports, :reporter_email, :string
    remove_column :reports, :evidence_url, :text
  end
end
