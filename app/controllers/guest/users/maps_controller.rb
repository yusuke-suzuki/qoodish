class Guest::Users::MapsController < ApplicationController
  def index
    @maps = Map
            .public_open
            .where(user_id: params[:user_id])
            .preload(:user, :reviews)
            .order(created_at: :desc)
  end
end
