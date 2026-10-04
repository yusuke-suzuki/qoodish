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
    property_options.reject { |option| option.offered_on?(pin.map_id) }
  end

  def single_choice_properties_given_several_options
    property_options.group_by(&:pin_property).filter_map do |property, options|
      property if !property.multiple? && options.many?
    end
  end
end
