class Guest::Maps::PinPropertiesController < ApplicationController
  def index
    map = Map.public_open.find_by!(id: params[:map_id])

    @pin_properties = map.pin_properties.published.preload(:options)
  end
end
