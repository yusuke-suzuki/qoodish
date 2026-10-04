# frozen_string_literal: true

module RevisionPropertyOptions
  extend ActiveSupport::Concern

  included do
    has_many :pin_revision_property_options, dependent: :destroy
    has_many :property_options,
             -> { order(:id) },
             through: :pin_revision_property_options,
             source: :pin_property_option

    with_options absence: { message: :invalid }, if: :property_options_submitted? do
      validates :property_options_not_offered_on_the_map
      validates :single_choice_properties_given_several_options
    end

    attr_writer :property_options_submitted
  end

  private

  def property_options_submitted?
    @property_options_submitted.present?
  end

  def property_options_not_offered_on_the_map
    property_options_with_their_properties.reject { |option| option.offered_on?(pin.map_id) }
  end

  def single_choice_properties_given_several_options
    property_options_with_their_properties.group_by(&:pin_property).filter_map do |property, options|
      property if !property.multiple? && options.many?
    end
  end

  def property_options_with_their_properties
    ActiveRecord::Associations::Preloader.new(records: property_options.to_a, associations: :pin_property).call
    property_options
  end
end
