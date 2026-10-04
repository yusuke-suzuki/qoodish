module Maps
  class PinsController < ApplicationController
    before_action :authenticate_user!

    def index
      @pins = current_user
              .referenceable_pins
              .where(map_id: params[:map_id])
              .preload(:map, { user: :image }, :images, :property_options, :votes)
              .order(created_at: :desc)

      @comments_by_pin_id = Comment
                            .not_deleted
                            .visible
                            .where(commentable: @pins.to_a)
                            .not_blocking(current_user)
                            .not_blocked_by(current_user)
                            .not_muted_by(current_user)
                            .preload({ user: :image }, :votes)
                            .group_by(&:commentable_id)
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
        .permit(:name, :comment, :latitude, :longitude, image_ids: [], property_option_ids: [])
        .to_h
        .symbolize_keys
    end
  end
end
