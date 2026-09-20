module Maps
  class PinsController < ApplicationController
    before_action :authenticate_user!

    def index
      @pins = current_user
              .referenceable_pins
              .where(map_id: params[:map_id])
              .preloaded_with_votes
              .order(created_at: :desc)
    end

    def create
      map = current_user
            .editable_maps
            .find_by!(id: params[:map_id])

      @pin = Pin.record!(user: current_user, map_id: map.id, **pin_params)
    end

    private

    def pin_params
      params
        .permit(:name, :comment, :latitude, :longitude, image_ids: [])
        .to_h
        .symbolize_keys
    end
  end
end
