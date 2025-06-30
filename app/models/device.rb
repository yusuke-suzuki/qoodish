class Device < ApplicationRecord
  belongs_to :user

  validates :user_id,
            presence: true
  validates :registration_token,
            presence: true,
            uniqueness: {
              scope: :user_id
            }
end
