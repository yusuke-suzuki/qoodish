class SearchQuery
  NGRAM_TOKEN_SIZE = 2

  attr_reader :terms

  def initialize(input)
    @terms = input.to_s.delete('"').split(/[[:space:]]+/).compact_blank.uniq
  end

  def blank?
    fulltext_terms.empty?
  end

  def fulltext_terms
    terms.select { |term| term.length >= NGRAM_TOKEN_SIZE }
  end

  def short_terms
    terms - fulltext_terms
  end

  def boolean_mode_query
    fulltext_terms.map { |term| %(+"#{term}") }.join(' ')
  end
end
