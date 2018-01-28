# == Schema Information
#
# Table name: users
#
#  id             :integer          not null, primary key
#  name           :string(255)
#  email          :string(255)
#  uid            :string(255)      not null
#  provider       :string(255)      not null
#  provider_uid   :string(255)      not null
#  provider_token :string(255)
#  image_path     :string(255)
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
