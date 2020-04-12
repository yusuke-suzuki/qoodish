module Maps
  module Spots
    class ReviewsController < ApplicationController
      before_action :authenticate_user!

      def index
        @reviews =
          current_user
            .referenceable_maps
            .find_by!(id: params[:map_id])
            .spots
            .find_by!(place_id_val: params[:spot_id])
            .reviews
            .includes([:map, :user, :images, :votes, :voters, comments: [:user, :votes, :voters]])
      end
    end
  end
end
