module FulltextSearchable
  extend ActiveSupport::Concern

  class_methods do
    def fulltext_searchable(*columns)
      qualified_columns = columns.map { |column| "#{table_name}.#{column}" }

      scope :search, lambda { |input|
        query = SearchQuery.new(input)
        next none if query.blank?

        relation = all

        if query.fulltext_terms.any?
          match = sanitize_sql_array(
            ["MATCH(#{qualified_columns.join(', ')}) AGAINST (? IN BOOLEAN MODE)", query.boolean_mode_query]
          )
          relation = relation.where(match).order(Arel.sql("#{match} DESC"))
        end

        query.short_terms.reduce(relation) do |narrowed, term|
          narrowed.where(
            qualified_columns.map { |column| "#{column} LIKE :term" }.join(' OR '),
            term: "%#{sanitize_sql_like(term)}%"
          )
        end
      }
    end
  end
end
