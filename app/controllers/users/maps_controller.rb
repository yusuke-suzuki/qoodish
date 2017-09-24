module Users
  class MapsController < ApplicationController
    before_action :authenticate_user!

    def index
      @maps = current_user.maps.includes(:user, :reviews).order(created_at: :desc)
    end
  end
end
