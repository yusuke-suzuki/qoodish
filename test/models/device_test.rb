# == Schema Information
#
# Table name: devices
#
#  id                 :integer          not null, primary key
#  user_id            :integer          not null
#  registration_token :string(255)      not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
# Indexes
#
#  index_devices_on_registration_token              (registration_token)
#  index_devices_on_user_id                         (user_id)
#  index_devices_on_user_id_and_registration_token  (user_id,registration_token) UNIQUE
#

require 'test_helper'

class DeviceTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
