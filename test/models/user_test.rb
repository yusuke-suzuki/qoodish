# == Schema Information
#
# Table name: users
#
#  id             :integer          not null, primary key
#  name           :string
#  email          :string
#  uid            :string           not null
#  provider       :string           not null
#  provider_uid   :string           not null
#  provider_token :string
#  image_path     :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_users_on_provider_and_provider_uid  (provider,provider_uid) UNIQUE
#  index_users_on_uid                        (uid)
#

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
