class Guest::Maps::PinsController < ApplicationController
  def index
    @pins = Pin
            .public_open
            .preload(:map, { user: :image }, :images, :votes, comments: [{ user: :image }, :votes])
            .where(map_id: params[:map_id])
            .order(created_at: :desc)
  end
end
