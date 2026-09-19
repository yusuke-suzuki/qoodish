class Guest::PinsController < ApplicationController
  def show
    @pin = Pin
           .public_open
           .preloaded
           .find_by!(id: params[:id])
  end

  def index
    @pins = if params[:feed]
              feed
            elsif params[:recent]
              Pin
                .public_open
                .limit(8)
                .preloaded
                .order(created_at: :desc)
            elsif params[:popular]
              Pin
                .public_open
                .popular
                .preloaded
            else
              raise Exceptions::BadRequest
            end
  end

  private

  def feed
    scope = Pin
            .public_open
            .preloaded

    if params[:next_timestamp]
      scope.feed_before(params[:next_timestamp], params[:next_id])
    else
      scope.latest_feed
    end
  end
end
