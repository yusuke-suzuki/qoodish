# frozen_string_literal: true

# Denormalizes the anchored review's name and coordinates at creation so the
# record stays renderable after the review changes or is removed.
module ReviewSnapshot
  extend ActiveSupport::Concern

  included do
    belongs_to :review, optional: true

    before_validation :snapshot_review_attributes, on: :create

    validates :review,
              presence: true,
              on: :create
    validates :name,
              presence: true
    validates :latitude,
              presence: true
    validates :longitude,
              presence: true
    validate :review_must_be_on_journey_map, on: :create
  end

  def lat
    latitude.to_f
  end

  def lng
    longitude.to_f
  end

  private

  def snapshot_review_attributes
    return if review.blank?

    self.name = review.name
    self.latitude = review.latitude
    self.longitude = review.longitude
  end

  def review_must_be_on_journey_map
    return if journey.blank? || review.blank?
    return if review.map_id == journey.map_id

    errors.add(:review_id, I18n.t('messages.api.review_not_on_journey_map'))
  end
end
