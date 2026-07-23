# frozen_string_literal: true

MAX_CHAPTER_CONTENT_BYTESIZE = 1.megabyte
CHAPTER_FEED_PER_PAGE = 12

class Chapter < ApplicationRecord
  belongs_to :user
  belongs_to :map, optional: true
  belongs_to :journey, optional: true
  has_many :votes, as: :votable, dependent: :destroy
  has_many :voters, through: :votes, source: :voter, source_type: User.name

  enum :status, { draft: 'draft', published: 'published' }, validate: true

  validates :title,
            presence: {
              message: I18n.t('messages.api.chapter_title_required')
            },
            length: {
              allow_blank: false,
              maximum: 100,
              message: I18n.t('messages.api.chapter_title_exceed')
            }
  validates :user_id,
            presence: true
  validates :map,
            presence: true,
            on: :create
  validates :journey_id,
            uniqueness: {
              allow_nil: true,
              message: I18n.t('messages.api.duplicate_chapter_for_journey')
            }
  validate :content_must_be_lexical_document
  validate :journey_must_match_author_and_map

  scope :referenceable_by, lambda { |user|
    published.where(map_id: Map.referenceable_by(user))
  }

  scope :readable_by, lambda { |user|
    referenceable_by(user).or(where(user_id: user.id))
  }

  scope :public_open, lambda {
    published.where(map_id: Map.public_open)
  }

  scope :liked_by, lambda { |user|
    where(id: Vote.where(voter: user, votable_type: name).select(:votable_id))
  }

  scope :feed_for, lambda { |user|
    published.where(map_id: Map.related_to(user))
  }

  scope :latest_feed, lambda {
    order(created_at: :desc)
      .limit(CHAPTER_FEED_PER_PAGE)
  }

  scope :feed_before, lambda { |created_at|
    where('chapters.created_at < ?', Time.parse(created_at))
      .order(created_at: :desc)
      .limit(CHAPTER_FEED_PER_PAGE)
  }

  def content=(value)
    super(value.is_a?(Hash) ? value.deep_stringify_keys : value)
  end

  def liked_by?(user)
    votes.any? { |vote| vote.voter_id == user.id }
  end

  def image_url
    map&.image_url.to_s
  end

  def image_variants
    map&.image_variants
  end

  private

  def content_must_be_lexical_document
    unless content.is_a?(Hash) && content['root'].is_a?(Hash)
      errors.add(:content, I18n.t('messages.api.chapter_content_invalid'))
      return
    end

    return if content.to_json.bytesize <= MAX_CHAPTER_CONTENT_BYTESIZE

    errors.add(:content, I18n.t('messages.api.chapter_content_exceed'))
  end

  def journey_must_match_author_and_map
    return if journey.blank?
    return if journey.user_id == user_id && journey.map_id == map_id

    errors.add(:journey_id, I18n.t('messages.api.chapter_journey_mismatch'))
  end
end
