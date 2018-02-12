
module Spots
  class ReviewsController < ApplicationController
    before_action :authenticate_user!

    def index
      @reviews = Review.includes(:user, :map).where(place_id_val: params[:spot_id]).select { |review| !review.map.private }
    end
  end
end
