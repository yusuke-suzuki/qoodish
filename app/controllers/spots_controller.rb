class SpotsController < ApplicationController
  before_action :authenticate_user!

  def index
    if params[:popular]
      @spots = Review.includes(:map).where(maps: { private: false }).group_by(&:place_id_val)
        .sort_by { |key, value| value.size }.reverse.take(10)
        .map { |key, value| value[0].spot }
    end
  end

  def show
    @spot = Spot.new(params[:id])
  end
end
