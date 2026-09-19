# frozen_string_literal: true

PIN_FEED_PER_PAGE = 12

class Pin < ApplicationRecord
  belongs_to :user
  belongs_to :map
  belongs_to :current_revision, class_name: 'PinRevision', optional: true
  has_many :revisions,
           -> { order(:id) },
           class_name: 'PinRevision',
           dependent: :destroy,
           inverse_of: :pin
  has_many :images, through: :current_revision
  has_many :notifications, as: :notifiable, dependent: :destroy
  has_many :comments, as: :commentable, dependent: :destroy
  has_many :votes, as: :votable, dependent: :destroy
  has_many :voters, through: :votes, source: :voter, source_type: User.name
  has_many :milestones, dependent: :nullify
  has_many :journey_checkins, dependent: :nullify

  enum :status, { published: 0, deleted: 1 }

  attr_accessor :revised_by, :submitted_image_ids

  after_save :append_revision, if: :revised_by
  before_destroy :detach_current_revision, prepend: true

  normalizes :name, :comment, with: ->(text) { text.delete("\r") }

  validates :comment,
            presence: {
              message: I18n.t('messages.api.comment_required')
            },
            length: {
              allow_blank: false,
              maximum: 500,
              message: I18n.t('messages.api.comment_exceeded')
            }
  validates :user_id,
            presence: true
  validates :map_id,
            presence: true
  validates :latitude,
            presence: true
  validates :longitude,
            presence: true
  validates :name,
            presence: true,
            length: {
              allow_blank: false,
              maximum: 100
            }

  scope :public_open, lambda {
    published
      .joins(:map)
      .where(maps: { private: false })
  }

  scope :referenceable_by, lambda { |user|
    published
      .joins(:map)
      .where(maps: { id: Map.referenceable_by(user) })
  }

  scope :feed_for, lambda { |user|
    published
      .joins(:map)
      .where(maps: { id: Map.related_to(user) })
  }

  scope :latest_feed, lambda {
    order(created_at: :desc, id: :desc)
      .limit(PIN_FEED_PER_PAGE)
  }

  scope :feed_before, lambda { |created_at, id = nil|
    where(*FeedCursor.new(created_at, id).condition('pins'))
      .order(created_at: :desc, id: :desc)
      .limit(PIN_FEED_PER_PAGE)
  }

  scope :popular, lambda {
    joins(:votes)
      .group('pins.id')
      .order('count(votes.id) desc')
      .limit(10)
  }

  scope :preloaded, lambda {
    preload(:map, { user: :images }, :images, { comments: { user: :images } })
  }

  scope :preloaded_with_votes, lambda {
    preloaded.preload(:voters, :votes)
  }

  def self.publish!(user:, map_id:, **content)
    new(user: user, map_id: map_id).revise!(user: user, **content)
  end

  def revise!(user:, image_ids: nil, **content)
    assign_attributes(**content, revised_by: user, submitted_image_ids: image_ids)
    save!

    self
  end

  def delete!(user:)
    revise!(user: user, status: :deleted)
  end

  def image_url
    images.first&.url.to_s
  end

  def image_variants
    images.first&.variants
  end

  def lat
    latitude.to_f
  end

  def lng
    longitude.to_f
  end

  private

  def append_revision
    revision = revisions.build(
      user: revised_by,
      status: status,
      name: name,
      comment: comment,
      latitude: latitude,
      longitude: longitude,
      images_submitted: !submitted_image_ids.nil?,
      image_ids: submitted_image_ids || current_revision&.image_ids || []
    )

    self.revised_by = nil
    self.submitted_image_ids = nil

    revision.save!
  end

  def detach_current_revision
    update_columns(current_revision_id: nil) if current_revision_id
  end
end
