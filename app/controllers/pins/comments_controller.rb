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

      @pin = current_user.referenceable_pins.preload(:map, { user: :image }, :images, :votes).find(pin.id)
      @comments = @pin
                  .comments
                  .not_blocking(current_user)
                  .not_blocked_by(current_user)
                  .not_muted_by(current_user)
                  .preload({ user: :image }, :votes)
    end

    def update
      pin = current_user.referenceable_pins.find_by!(id: params[:pin_id])

      comment = current_user.comments.find_by!(id: params[:id], commentable: pin)
      comment.revise!(user: current_user, body: params[:comment])

      @pin = current_user.referenceable_pins.preload(:map, { user: :image }, :images, :votes).find(pin.id)
      @comments = @pin
                  .comments
                  .not_blocking(current_user)
                  .not_blocked_by(current_user)
                  .not_muted_by(current_user)
                  .preload({ user: :image }, :votes)
    end

    def destroy
      pin = current_user.referenceable_pins.find_by!(id: params[:pin_id])

      comment = current_user.comments.find_by!(id: params[:id], commentable: pin)
      comment.discard!(user: current_user)

      @pin = current_user.referenceable_pins.preload(:map, { user: :image }, :images, :votes).find(pin.id)
      @comments = @pin
                  .comments
                  .not_blocking(current_user)
                  .not_blocked_by(current_user)
                  .not_muted_by(current_user)
                  .preload({ user: :image }, :votes)
    end
  end
end
