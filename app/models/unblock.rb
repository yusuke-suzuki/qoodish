class Unblock < ApplicationRecord
  belongs_to :block

  validates :block_id, uniqueness: true

  def readonly?
    persisted?
  end
end
