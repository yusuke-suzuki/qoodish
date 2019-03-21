module Spots
  class ReviewsController < ApplicationController
    before_action :authenticate_user!

    def index
      @reviews =
        current_user
        .referenceable_reviews
        .includes(:user, :map, :comments)
        .where(reviews: { place_id_val: params[:spot_id] })
    end
  end
end
