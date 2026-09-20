# frozen_string_literal: true

MAX_IMAGE_COUNT_PER_CHAPTER = 1

class ChapterRevision < ApplicationRecord
  include Revision

  belongs_to :chapter
  belongs_to :user
  has_many :chapter_revision_images, dependent: :destroy
  has_many :images, -> { order(:id) }, through: :chapter_revision_images

  alias_method :revisable, :chapter

  enum :status, { draft: 'draft', published: 'published', deleted: 'deleted' }, validate: true

  attr_readonly :chapter_id, :user_id, :title, :content, :map_features, :status

  validates :title,
            presence: true
  # The limit judges what a caller may submit, not what a revision may record.
  # A chapter backfilled from the legacy imageable column can already hold more
  # images than it allows, and its history has to stay recordable and its later
  # revisions possible.
  validates :images,
            length: { maximum: MAX_IMAGE_COUNT_PER_CHAPTER },
            if: :images_submitted?
end
