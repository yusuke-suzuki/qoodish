# frozen_string_literal: true

PIN_FEED_PER_PAGE = 12

class Pin < ApplicationRecord
  include Revisable

  self.revision_attributes = %i[name comment latitude longitude]

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
      .where(maps: { id: Map.public_open })
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
end
