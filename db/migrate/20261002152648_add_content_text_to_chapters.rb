class AddContentTextToChapters < ActiveRecord::Migration[8.1]
  def up
    unless column_exists?(:chapters, :content_text)
      add_column :chapters, :content_text, :virtual,
                 type: :text,
                 size: :medium,
                 as: "JSON_UNQUOTE(JSON_EXTRACT(content, '$**.text'))",
                 stored: true
    end

    return if index_name_exists?(:chapters, :index_chapters_on_title_and_content_text)

    execute 'CREATE FULLTEXT INDEX index_chapters_on_title_and_content_text ' \
            'ON chapters (title, content_text) WITH PARSER ngram'
  end

  def down
    remove_index :chapters, name: :index_chapters_on_title_and_content_text, if_exists: true
    remove_column :chapters, :content_text, if_exists: true
  end
end
