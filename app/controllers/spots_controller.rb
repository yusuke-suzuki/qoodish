class SpotsController < ApplicationController
  before_action :authenticate_user!

  def index
    if params[:popular]
      @places =
        Place.popular
    end
  end

  def show
    @place = Place.find_by!(place_id_val: params[:id])
  end
end
