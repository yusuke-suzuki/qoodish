module Pins
  module Comments
    class LikesController < ApplicationController
      before_action :authenticate_user!

      def index
        pin = current_user.referenceable_pins.find_by!(id: params[:pin_id])

        comment = pin.comments.find_by!(id: params[:comment_id])

        @likes = comment.votes
      end

      def create
        pin = current_user.referenceable_pins.find_by!(id: params[:pin_id])

        current_user.liked!(pin.comments.find_by!(id: params[:comment_id]))

        @pin = current_user.referenceable_pins.preloaded.find(pin.id)
      end

      def destroy
        pin = current_user.referenceable_pins.find_by!(id: params[:pin_id])

        current_user.unliked!(pin.comments.find_by!(id: params[:comment_id]))

        @pin = current_user.referenceable_pins.preloaded.find(pin.id)
      end
    end
  end
end
