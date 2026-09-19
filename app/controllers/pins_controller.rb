class PinsController < ApplicationController
  before_action :authenticate_user!

  def index
    @pins = if params[:next_timestamp]
              Pin
                .feed_for(current_user)
                .feed_before(params[:next_timestamp], params[:next_id])
                .preloaded_with_votes
            else
              Pin
                .feed_for(current_user)
                .latest_feed
                .preloaded_with_votes
            end
  end

  def show
    @pin =
      current_user
      .referenceable_pins
      .preloaded_with_votes
      .find_by!(id: params[:id])
  end
end
