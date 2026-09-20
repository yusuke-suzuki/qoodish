class Guest::Users::MapsController < ApplicationController
  def index
    @maps = Map
            .public_open
            .where(user_id: params[:user_id])
            .preload(:images, user: :image)
            .order(created_at: :desc)
  end
end
