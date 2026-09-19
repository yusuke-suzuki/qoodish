module Users
  class PinsController < ApplicationController
    before_action :authenticate_user!

    def index
      user = User.find_by!(id: params[:user_id])

      pins = user
             .pins
             .preloaded_with_votes
             .referenceable_by(current_user)

      @pins = if params[:next_timestamp]
                pins.feed_before(params[:next_timestamp], params[:next_id])
              else
                pins.latest_feed
              end
    end
  end
end
