class SpotsController < ApplicationController
  def show
    @spot = Spot.new(params[:id])
  end
end
