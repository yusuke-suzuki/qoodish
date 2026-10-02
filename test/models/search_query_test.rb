require 'test_helper'

class SearchQueryTest < ActiveSupport::TestCase
  test 'splits terms on half-width and full-width spaces' do
    assert_equal %w[ラーメン 渋谷 tea], SearchQuery.new(" ラーメン　渋谷  tea ").terms
  end

  test 'drops double quotes so a term cannot break out of its phrase' do
    assert_equal ['coffee'], SearchQuery.new('"coffee"').terms
  end

  test 'ignores repeated terms' do
    assert_equal ['tea'], SearchQuery.new('tea tea').terms
  end

  test 'is blank without terms' do
    assert_predicate SearchQuery.new(nil), :blank?
    assert_predicate SearchQuery.new(' 　"'), :blank?
  end

  test 'is blank with only terms shorter than an n-gram' do
    assert_predicate SearchQuery.new('京 a'), :blank?
    assert_not_predicate SearchQuery.new('京 京都'), :blank?
  end

  test 'leaves terms shorter than an n-gram to substring matching' do
    query = SearchQuery.new('京 京都 a')

    assert_equal ['京都'], query.fulltext_terms
    assert_equal %w[京 a], query.short_terms
  end

  test 'requires every full-text term as a phrase' do
    assert_equal '+"ラーメン" +"渋谷"', SearchQuery.new('ラーメン 渋谷').boolean_mode_query
  end
end
