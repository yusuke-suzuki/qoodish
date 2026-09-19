class Guest::Users::PinsController < ApplicationController
  def index
    scope = Pin
            .public_open
            .where(user_id: params[:user_id])
            .preloaded

    @pins = if params[:next_timestamp]
              scope.feed_before(params[:next_timestamp], params[:next_id])
            else
              scope.latest_feed
            end
  end
end
