module Me
  class PinsController < ApplicationController
    before_action :authenticate_user!

    def update
      pin = current_user.pins.published.find_by!(id: params[:id])
      pin.revise!(user: current_user, **pin_params)

      @pin = current_user.pins.preload(:map, :images, :property_options, :votes).find(pin.id)
      @comments = @pin
                  .comments
                  .not_blocking(current_user)
                  .not_blocked_by(current_user)
                  .not_muted_by(current_user)
                  .preload({ user: :image }, :votes)
    end

    def destroy
      current_user.pins.published.find_by!(id: params[:id]).discard!(user: current_user)
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
