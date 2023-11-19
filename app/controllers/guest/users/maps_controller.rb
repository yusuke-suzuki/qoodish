class Guest::Users::MapsController < ApplicationController
  def index
    @maps = Map
            .public_open
            .where(user_id: params[:user_id])
            .preload(:user)
            .order(created_at: :desc)
  end
end
