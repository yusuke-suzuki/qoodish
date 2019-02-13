class Invite < ApplicationRecord
  belongs_to :invitable, polymorphic: true
  belongs_to :sender, polymorphic: true
  belongs_to :recipient, polymorphic: true

  def invitable_name
    case invitable_type
    when Map.name
      'map'
    else
      ''
    end
  end
end
