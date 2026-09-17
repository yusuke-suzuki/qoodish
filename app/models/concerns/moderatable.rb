module Moderatable
  extend ActiveSupport::Concern

  included do
    moderatable_type = name

    scope :visible, -> { where.not(id: ModerationDecision.removed_ids(moderatable_type)) }
  end
end
