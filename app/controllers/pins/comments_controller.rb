module Pins
  class CommentsController < ApplicationController
    before_action :authenticate_user!

    def create
      pin = current_user.referenceable_pins.find_by!(id: params[:pin_id])

      pin.comments.create!(
        user: current_user,
        body: params[:comment]
      )

      @pin = current_user.referenceable_pins.preloaded.find(pin.id)
    end

    def destroy
      pin = current_user.referenceable_pins.find_by!(id: params[:pin_id])

      current_user
        .comments
        .find_by!(id: params[:id], commentable: pin)
        .discard!

      @pin = current_user.referenceable_pins.preloaded.find(pin.id)
    end
  end
end
