module Blockable
  extend ActiveSupport::Concern

  included do
    scope :not_blocking, lambda { |user|
      where.not(user_id: Block.active.where(blocked_id: user.id).select(:blocker_id))
    }

    scope :not_blocked_by, lambda { |user|
      where.not(user_id: Block.active.where(blocker_id: user.id).select(:blocked_id))
    }
  end
end
