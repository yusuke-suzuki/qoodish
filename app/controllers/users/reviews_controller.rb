module Users
  class ReviewsController < ApplicationController
    before_action :authenticate_user!

    def index
      @reviews =
        if params[:next_timestamp]
          current_user.reviews.my_feed_before(params[:next_timestamp])
        else
          current_user.reviews.my_feed
        end
    end
  end
end
