class PushNotification < ApplicationRecord
  belongs_to :user

  validates :user_id,
            presence: true,
            uniqueness: true
end
