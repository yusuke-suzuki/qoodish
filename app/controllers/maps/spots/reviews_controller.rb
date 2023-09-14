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
          .find_by!(place: Place.find_by!(place_id_val: params[:spot_id]))
          .reviews
          .with_deps
      end
    end
  end
end
