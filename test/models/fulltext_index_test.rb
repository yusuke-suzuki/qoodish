require 'test_helper'

class FulltextIndexTest < ActiveSupport::TestCase
  test 'maps index n-grams that contain stopwords' do
    found = Map.where('MATCH(name, description) AGAINST (? IN BOOLEAN MODE)', '+"map"')

    assert_includes found, maps(:public_one)
  end

  test 'pins index n-grams that are stopwords' do
    found = Pin.where('MATCH(name, comment) AGAINST (? IN BOOLEAN MODE)', '+"is"')

    assert_includes found, pins(:public_one)
  end

  test 'users index n-grams that contain stopwords' do
    found = User.where('MATCH(name) AGAINST (? IN BOOLEAN MODE)', '+"wata"')

    assert_includes found, users(:me)
  end
end
