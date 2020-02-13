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
              .with_deps
          else
            current_user
              .reviews
              .latest_feed
              .with_deps
          end
        else
          user = User.find_by!(id: params[:user_id])
          if params[:next_timestamp]
            user
              .reviews
              .referenceable_by(current_user)
              .feed_before(params[:next_timestamp])
              .with_deps
          else
            user
              .reviews
              .referenceable_by(current_user)
              .latest_feed
              .with_deps
          end
        end
    end
  end
end
