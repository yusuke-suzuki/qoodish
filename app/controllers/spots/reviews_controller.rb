
module Spots
  class ReviewsController < ApplicationController
    before_action :authenticate_user!

    def index
      @reviews = Review.includes(:user, :map, :comments).where(reviews: { place_id_val: params[:spot_id] }, maps: { private: false })
    end
  end
end
