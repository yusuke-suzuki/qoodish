# frozen_string_literal: true

class PinRevisionImage < ApplicationRecord
  belongs_to :pin_revision
  belongs_to :image

  attr_readonly :pin_revision_id, :image_id
end
