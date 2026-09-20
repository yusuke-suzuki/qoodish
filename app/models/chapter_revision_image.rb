# frozen_string_literal: true

class ChapterRevisionImage < ApplicationRecord
  belongs_to :chapter_revision
  belongs_to :image

  attr_readonly :chapter_revision_id, :image_id
end
