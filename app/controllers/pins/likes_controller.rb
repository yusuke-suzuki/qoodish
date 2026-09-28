module Pins
  class LikesController < ApplicationController
    before_action :authenticate_user!

    def index
      pin = current_user.referenceable_pins.find_by!(id: params[:pin_id])

      @likes = pin.votes.uniq { |vote| vote.voter.id }
    end

    def create
      pin = current_user.referenceable_pins.find_by!(id: params[:pin_id])

      current_user.liked!(pin)

      @pin = current_user.referenceable_pins.preload(:map, { user: :image }, :images, :votes).find(pin.id)
      @comments = @pin
                  .comments
                  .not_blocking(current_user)
                  .not_blocked_by(current_user)
                  .preload({ user: :image }, :votes)
    end

    def destroy
      pin = current_user.referenceable_pins.find_by!(id: params[:pin_id])

      current_user.unliked!(pin)

      @pin = current_user.referenceable_pins.preload(:map, { user: :image }, :images, :votes).find(pin.id)
      @comments = @pin
                  .comments
                  .not_blocking(current_user)
                  .not_blocked_by(current_user)
                  .preload({ user: :image }, :votes)
    end
  end
end
