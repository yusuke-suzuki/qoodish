# frozen_string_literal: true

class MapRevisionImage < ApplicationRecord
  belongs_to :map_revision
  belongs_to :image

  attr_readonly :map_revision_id, :image_id
end
