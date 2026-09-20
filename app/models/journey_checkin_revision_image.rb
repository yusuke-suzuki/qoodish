# frozen_string_literal: true

class JourneyCheckinRevisionImage < ApplicationRecord
  belongs_to :journey_checkin_revision
  belongs_to :image

  attr_readonly :journey_checkin_revision_id, :image_id
end
