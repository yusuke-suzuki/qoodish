module Users
  class ReviewsController < ApplicationController
    before_action :authenticate_user!

    def index
      @reviews =
        if params[:user_id] == current_user.uid
          if params[:next_timestamp]
            current_user.reviews.user_feed_before(params[:next_timestamp])
          else
            current_user.reviews.user_feed
          end
        else
          user = User.find_by!(id: params[:user_id])
          if params[:next_timestamp]
            user.reviews.includes(:user, :map).where(maps: { private: false }).user_feed_before(params[:next_timestamp])
          else
            user.reviews.includes(:user, :map).where(maps: { private: false }).user_feed
          end
        end
    end
  end
end
