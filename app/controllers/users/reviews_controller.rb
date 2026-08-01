module Users
  class ReviewsController < ApplicationController
    before_action :authenticate_user!

    def index
      user = User.find_by!(id: params[:user_id])

      reviews = user
                .reviews
                .preload(:map, { user: :images }, :images, { comments: { user: :images } })
                .referenceable_by(current_user)

      @reviews = if params[:next_timestamp]
                   reviews.feed_before(params[:next_timestamp])
                 else
                   reviews.latest_feed
                 end
    end
  end
end
