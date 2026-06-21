require 'test_helper'

class CoauthorshipTest < ActiveSupport::TestCase
  test 'valid coauthorship' do
    coauthorship = Coauthorship.new(map: maps(:public_one), user: users(:you))

    assert coauthorship.valid?
  end

  test 'author cannot be a coauthor' do
    coauthorship = Coauthorship.new(map: maps(:public_one), user: maps(:public_one).user)

    assert_not coauthorship.valid?
  end

  test 'same user cannot be a coauthor of the same map twice' do
    existing = coauthorships(:you_on_my_private)
    duplicate = Coauthorship.new(map: existing.map, user: existing.user)

    assert_not duplicate.valid?
  end
end
