# frozen_string_literal: true

class PinRevisionPropertyOption < ApplicationRecord
  belongs_to :pin_revision
  belongs_to :pin_property_option

  attr_readonly :pin_revision_id, :pin_property_option_id
end
