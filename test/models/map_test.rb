# == Schema Information
#
# Table name: maps
#
#  id          :integer          not null, primary key
#  user_id     :integer          not null
#  name        :string(255)      not null
#  description :string(255)      not null
#  private     :boolean          default(TRUE)
#  invitable   :boolean          default(FALSE)
#  shared      :boolean          default(FALSE)
#  base_id_val :string(255)
#  base_name   :string(255)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_maps_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#

require 'test_helper'

class MapTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
