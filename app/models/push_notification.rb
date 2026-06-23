class PushNotification < ApplicationRecord
  # Shield running instances from the legacy columns the follow-up migration
  # drops, so in-flight INSERTs do not reference a column that is gone.
  self.ignored_columns += %w[followed invited]

  belongs_to :user

  validates :user_id,
            presence: true,
            uniqueness: true
end
