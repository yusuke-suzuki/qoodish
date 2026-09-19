# frozen_string_literal: true

# Denormalizes the anchored pin's name and coordinates at creation so the
# record stays renderable after the pin changes or is removed.
module PinSnapshot
  extend ActiveSupport::Concern

  included do
    belongs_to :pin, optional: true

    before_validation :snapshot_pin_attributes, on: :create

    validates :pin,
              presence: true,
              on: :create
    validates :name,
              presence: true
    validates :latitude,
              presence: true
    validates :longitude,
              presence: true
    validate :pin_must_be_on_journey_map, on: :create
  end

  def lat
    latitude.to_f
  end

  def lng
    longitude.to_f
  end

  private

  def snapshot_pin_attributes
    return if pin.blank?

    self.name = pin.name
    self.latitude = pin.latitude
    self.longitude = pin.longitude
  end

  def pin_must_be_on_journey_map
    return if journey.blank? || pin.blank?
    return if pin.map_id == journey.map_id

    errors.add(:pin_id, I18n.t('messages.api.pin_not_on_journey_map'))
  end
end
