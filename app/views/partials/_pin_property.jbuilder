json.id pin_property.id
json.name pin_property.name
json.multiple pin_property.multiple
json.position pin_property.position
json.options pin_property.options.select(&:published?),
             partial: 'partials/pin_property_option',
             as: :option
