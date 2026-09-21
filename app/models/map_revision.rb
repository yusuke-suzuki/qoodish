# frozen_string_literal: true

MAX_IMAGE_COUNT_PER_MAP = 1

class MapRevision < ApplicationRecord
  include Revision
  include RevisionImages

  belongs_to :map
  # A coauthor may revise a map they do not own, so erasing their account has
  # to leave the revision standing with nobody named.
  belongs_to :user, optional: true
  has_many :map_revision_images, dependent: :destroy
  has_many :images, -> { order(:id) }, through: :map_revision_images

  alias_method :revisable, :map

  enum :status, { published: 'published', deleted: 'deleted' }, validate: true

  attr_readonly :map_id, :user_id, :name, :description, :latitude, :longitude, :private, :status

  validates :name,
            presence: true
  validates :description,
            presence: true
  validates :latitude,
            presence: true
  validates :longitude,
            presence: true
  # The limit judges what a caller may submit, not what a revision may record.
  # A map backfilled from the legacy image_url column can already hold more
  # images than it allows, and its history has to stay recordable and its later
  # revisions possible.
  validates :images,
            length: { maximum: MAX_IMAGE_COUNT_PER_MAP },
            if: :images_submitted?
end
