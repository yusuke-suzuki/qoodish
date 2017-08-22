# == Schema Information
#
# Table name: maps
#
#  id          :integer          not null, primary key
#  user_id     :integer          not null
#  name        :string           not null
#  description :string           not null
#  private     :boolean          default(TRUE)
#  invitable   :boolean          default(FALSE)
#  shared      :boolean          default(FALSE)
#  base_id_val :string
#  base_name   :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_maps_on_user_id  (user_id)
#

require 'test_helper'

class MapTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
