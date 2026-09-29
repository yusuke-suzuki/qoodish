class Unmute < ApplicationRecord
  belongs_to :mute

  validates :mute_id, uniqueness: true

  def readonly?
    persisted?
  end
end
