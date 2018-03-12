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

class Device < ApplicationRecord
  belongs_to :user

  validates :user_id,
            presence: true
  validates :registration_token,
            presence: {
              strict: Exceptions::RegistrationTokenNotSpecified
            },
            uniqueness: {
              scope: :user_id,
              strict: Exceptions::DuplicateRegistrationToken
            }
end
