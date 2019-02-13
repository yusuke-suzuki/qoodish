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
