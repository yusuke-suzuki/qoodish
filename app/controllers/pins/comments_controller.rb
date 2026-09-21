module Pins
  class CommentsController < ApplicationController
    before_action :authenticate_user!

    def create
      pin = current_user.referenceable_pins.find_by!(id: params[:pin_id])

      Comment.record!(
        user: current_user,
        commentable: pin,
        body: params[:comment]
      )

      @pin = current_user.referenceable_pins.preloaded.find(pin.id)
    end

    def update
      pin = current_user.referenceable_pins.find_by!(id: params[:pin_id])

      own_comment_on(pin).revise!(user: current_user, body: params[:comment])

      @pin = current_user.referenceable_pins.preloaded.find(pin.id)
    end

    def destroy
      pin = current_user.referenceable_pins.find_by!(id: params[:pin_id])

      own_comment_on(pin).discard!(user: current_user)

      @pin = current_user.referenceable_pins.preloaded.find(pin.id)
    end

    private

    def own_comment_on(pin)
      current_user
        .comments
        .find_by!(id: params[:id], commentable: pin)
    end
  end
end
