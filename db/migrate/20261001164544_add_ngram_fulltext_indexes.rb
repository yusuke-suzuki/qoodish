class AddNgramFulltextIndexes < ActiveRecord::Migration[8.1]
  def up
    add_ngram_index :maps, %i[name description], :index_maps_on_name_and_description
    add_ngram_index :pins, %i[name comment], :index_pins_on_name_and_comment
    add_ngram_index :users, %i[name], :index_users_on_name
  end

  def down
    remove_index :users, name: :index_users_on_name, if_exists: true
    remove_index :pins, name: :index_pins_on_name_and_comment, if_exists: true
    remove_index :maps, name: :index_maps_on_name_and_description, if_exists: true
  end

  private

  def add_ngram_index(table, columns, name)
    return if index_name_exists?(table, name)

    execute "CREATE FULLTEXT INDEX #{name} ON #{table} (#{columns.join(', ')}) WITH PARSER ngram"
  end
end
