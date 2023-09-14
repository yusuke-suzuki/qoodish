class SpotsController < ApplicationController
  before_action :authenticate_user!

  def index
    return unless params[:popular]

    @places =
      Place.popular
  end

  def show
    @place = Place.find_by!(place_id_val: params[:id])
  end
end
