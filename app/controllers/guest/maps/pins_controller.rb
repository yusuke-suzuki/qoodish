class Guest::Maps::PinsController < ApplicationController
  def index
    @pins = Pin
            .public_open
            .preloaded_with_votes
            .where(map_id: params[:map_id])
            .order(created_at: :desc)
  end
end
