class PinsController < ApplicationController
  before_action :authenticate_user!

  def show
    @pin =
      current_user
      .referenceable_pins
      .preload(:map, { user: :image }, :images, :property_options, :votes)
      .find_by!(id: params[:id])

    @comments = @pin
                .comments
                .not_blocking(current_user)
                .not_blocked_by(current_user)
                .not_muted_by(current_user)
                .preload({ user: :image }, :votes)
  end
end
