module Users
  class ReviewsController < ApplicationController
    before_action :authenticate_user!

    def index
      @reviews =
        if params[:user_id] == current_user.uid
          if params[:next_timestamp]
            current_user
              .reviews
              .feed_before(params[:next_timestamp])
              .includes(:user, :map, :comments)
          else
            current_user
              .reviews
              .latest_feed
              .includes(:user, :map, :comments)
          end
        else
          user = User.find_by!(id: params[:user_id])
          if params[:next_timestamp]
            user
              .reviews
              .referenceable_by(current_user)
              .feed_before(params[:next_timestamp])
              .includes(:user, :map, :comments)
          else
            user
              .reviews
              .referenceable_by(current_user)
              .latest_feed
              .includes(:user, :map, :comments)
          end
        end
    end
  end
end
