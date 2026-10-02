class RebuildFulltextIndexesWithoutStopwords < ActiveRecord::Migration[8.1]
  INDEXES = {
    maps: { columns: %i[name description], name: :index_maps_on_name_and_description },
    pins: { columns: %i[name comment], name: :index_pins_on_name_and_comment },
    users: { columns: %i[name], name: :index_users_on_name }
  }.freeze

  def up
    rebuild_indexes(stopwords: false)
  end

  def down
    rebuild_indexes(stopwords: true)
  end

  private

  def rebuild_indexes(stopwords:)
    execute "SET SESSION innodb_ft_enable_stopword = #{stopwords ? 'ON' : 'OFF'}"

    INDEXES.each do |table, index|
      remove_index table, name: index[:name], if_exists: true
      execute "CREATE FULLTEXT INDEX #{index[:name]} ON #{table} (#{index[:columns].join(', ')}) WITH PARSER ngram"
    end
  ensure
    execute 'SET SESSION innodb_ft_enable_stopword = OFF'
  end
end
