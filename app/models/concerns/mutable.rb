module Mutable
  extend ActiveSupport::Concern

  included do
    scope :not_muted_by, lambda { |user|
      where.not(user_id: Mute.active.where(muter_id: user.id).select(:muted_id))
    }
  end
end
