class CreateCommentRevisions < ActiveRecord::Migration[8.1]
  def change
    create_table :comment_revisions do |t|
      t.references :comment, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :body, null: false
      t.string :status, null: false, default: 'published'

      t.timestamps

      t.index %i[comment_id id]
    end
  end
end
