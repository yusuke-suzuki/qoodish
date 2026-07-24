# frozen_string_literal: true

MAX_CHAPTER_CONTENT_BYTESIZE = 1.megabyte
MAX_CHAPTER_MAP_FEATURES_BYTESIZE = 100.kilobytes
CHAPTER_FEED_PER_PAGE = 12

class Chapter < ApplicationRecord
  EMPTY_FEATURE_COLLECTION = { 'type' => 'FeatureCollection', 'features' => [] }.freeze

  # Styling keys from the simplestyle spec (marker-color, marker-symbol) are
  # deliberately absent until there is UI to set them; unknown keys pass so
  # documents imported from other GeoJSON tools survive a round trip.
  FEATURE_TEXT_PROPERTIES = %w[title description].freeze

  attribute :map_features, default: -> { EMPTY_FEATURE_COLLECTION.deep_dup }

  belongs_to :user
  belongs_to :map, optional: true
  belongs_to :journey, optional: true
  has_many :votes, as: :votable, dependent: :destroy
  has_many :voters, through: :votes, source: :voter, source_type: User.name
  has_many :images, as: :imageable, dependent: :destroy

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
  validates :images, length: { maximum: 1 }
  validate :content_must_be_lexical_document
  validate :map_features_must_be_geojson_features
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

  def map_features=(value)
    super(value.is_a?(Hash) ? value.deep_stringify_keys : value)
  end

  def liked_by?(user)
    votes.any? { |vote| vote.voter_id == user.id }
  end

  def image_url
    images.first&.url.to_s
  end

  def image_variants
    primary = images.first
    return nil unless primary

    Cloudflare::Images::NAMED_VARIANTS
      .index_with { |variant| Cloudflare::Images.variant_url(primary.url, variant) }
      .merge(url: primary.url)
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

  def map_features_must_be_geojson_features
    unless feature_collection?(map_features)
      errors.add(:map_features, I18n.t('messages.api.chapter_map_features_invalid'))
      return
    end

    return if map_features.to_json.bytesize <= MAX_CHAPTER_MAP_FEATURES_BYTESIZE

    errors.add(:map_features, I18n.t('messages.api.chapter_map_features_exceed'))
  end

  def feature_collection?(document)
    document.is_a?(Hash) &&
      document['type'] == 'FeatureCollection' &&
      document['features'].is_a?(Array) &&
      document['features'].all? { |feature| point_feature?(feature) }
  end

  # Point is the only geometry served to readers so far; widening this check
  # per geometry type is how LineString and Polygon get introduced.
  def point_feature?(feature)
    feature.is_a?(Hash) &&
      feature['type'] == 'Feature' &&
      feature_properties?(feature['properties']) &&
      feature['geometry'].is_a?(Hash) &&
      feature['geometry']['type'] == 'Point' &&
      point_coordinates?(feature['geometry']['coordinates'])
  end

  def feature_properties?(properties)
    return true if properties.nil?

    properties.is_a?(Hash) &&
      FEATURE_TEXT_PROPERTIES.all? do |key|
        properties[key].nil? || properties[key].is_a?(String)
      end
  end

  def point_coordinates?(coordinates)
    coordinates.is_a?(Array) &&
      coordinates.length == 2 &&
      coordinates.all? { |value| value.is_a?(Numeric) } &&
      coordinates[0].between?(-180, 180) &&
      coordinates[1].between?(-90, 90)
  end
end
