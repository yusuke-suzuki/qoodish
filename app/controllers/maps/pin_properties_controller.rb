module Maps
  class PinPropertiesController < ApplicationController
    before_action :authenticate_user!

    def index
      map = current_user.referenceable_maps.find_by!(id: params[:map_id])

      @pin_properties = map.pin_properties.published.preload(:options)
    end

    def create
      map = current_user.editable_maps.find_by!(id: params[:map_id])

      @pin_property = PinProperty.record!(
        user: current_user,
        map: map,
        **params.permit(:name, :position, :multiple).to_h.symbolize_keys
      )
    end

    def update
      @pin_property = editable_pin_properties.preload(:options).find_by!(id: params[:id])
      @pin_property.revise!(user: current_user, **params.permit(:name, :position).to_h.symbolize_keys)
    end

    def destroy
      editable_pin_properties.find_by!(id: params[:id]).discard!(user: current_user)
    end

    private

    def editable_pin_properties
      PinProperty
        .published
        .where(map_id: params[:map_id], map: current_user.editable_maps)
    end
  end
end
