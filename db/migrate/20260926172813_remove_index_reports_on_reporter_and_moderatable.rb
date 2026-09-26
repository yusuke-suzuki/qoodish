class RemoveIndexReportsOnReporterAndModeratable < ActiveRecord::Migration[8.1]
  def change
    remove_index :reports, %i[reporter_id moderatable_type moderatable_id],
                 name: 'index_reports_on_reporter_and_moderatable', unique: true
  end
end
