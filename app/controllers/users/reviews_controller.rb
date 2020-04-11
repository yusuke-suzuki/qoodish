module Users
  class ReviewsController < ApplicationController
    before_action :authenticate_user!

    def index
      @reviews =
        if params[:user_id] == current_user.uid
          if params[:next_timestamp]
            current_user
              .reviews
              .includes([:comments, :images, :spot, :map])
              .feed_before(params[:next_timestamp])
          else
            current_user
              .reviews
              .includes([:comments, :images, :spot, :map])
              .latest_feed
          end
        else
          user = User.find_by!(id: params[:user_id])
          if params[:next_timestamp]
            user
              .reviews
              .includes([:comments, :images, :spot, :map])
              .referenceable_by(current_user)
              .feed_before(params[:next_timestamp])
          else
            user
              .reviews
              .includes([:comments, :images, :spot, :map])
              .referenceable_by(current_user)
              .latest_feed
          end
        end
    end
  end
end
