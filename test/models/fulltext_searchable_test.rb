require 'test_helper'

class FulltextSearchableTest < ActiveSupport::TestCase
  test 'finds maps by Japanese words in the name or the description' do
    assert_equal [maps(:tokyo_cafe), maps(:ramen_alley)].sort_by(&:id), Map.search('ラーメン').sort_by(&:id)
  end

  test 'ranks by relevance before any ordering added after the search' do
    assert_equal [maps(:tokyo_cafe), maps(:ramen_alley)], Map.search('ラーメン').order(created_at: :desc).to_a
  end

  test 'requires every term to match' do
    assert_equal [maps(:ramen_alley)], Map.search('ラーメン 横丁').to_a
  end

  test 'finds nothing for single character terms alone' do
    assert_empty Map.search('横')
  end

  test 'narrows longer terms by single character terms as substrings' do
    assert_equal [maps(:tokyo_cafe)], Map.search('東 ラーメン').to_a
  end

  test 'treats LIKE wildcards in a single character term literally' do
    assert_empty Map.search('ラーメン %')
    assert_empty Map.search('ラーメン _')
  end

  test 'finds nothing without terms' do
    assert_empty Map.search(' ')
  end

  test 'matches English terms regardless of case' do
    assert_includes Map.search('PUBLIC two'), maps(:public_two)
    assert_not_includes Map.search('PUBLIC two'), maps(:public_one)
  end

  test 'finds pins by their name or comment on public maps' do
    assert_equal [pins(:ramen_alley)], Pin.public_open.search('醤油 broth').to_a
  end

  test 'finds users by name' do
    assert_equal [users(:you)], User.search('kay').to_a
  end
end
