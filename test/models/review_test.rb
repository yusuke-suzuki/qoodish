# == Schema Information
#
# Table name: reviews
#
#  id           :integer          not null, primary key
#  user_id      :integer          not null
#  map_id       :integer          not null
#  place_id_val :string           not null
#  comment      :string           not null
#  image_url    :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_reviews_on_map_id                               (map_id)
#  index_reviews_on_place_id_val                         (place_id_val)
#  index_reviews_on_place_id_val_and_map_id_and_user_id  (place_id_val,map_id,user_id) UNIQUE
#  index_reviews_on_user_id                              (user_id)
#

require 'test_helper'

class ReviewTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
