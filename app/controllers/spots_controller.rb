class SpotsController < ApplicationController
  before_action :authenticate_user!

  def index
    if params[:popular]
      @spots =
        Review
        .public_open
        .group_by(&:place_id_val)
        .sort_by { |_key, value| value.size }
        .reverse
        .take(10)
        .map { |_key, value| value[0].spot }
    end
  end

  def show
    @spot = Spot.new(params[:id])
  end
end
