class SpotsController < ApplicationController
  before_action :authenticate_user!

  def show
    @spot = Spot.new(params[:id])
  end
end
