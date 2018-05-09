module Users
  class MapsController < ApplicationController
    before_action :authenticate_user!

    def index
      @maps =
        if params[:user_id] == current_user.uid
          current_user.maps.includes(:user, :reviews).order(created_at: :desc)
        else
          user = User.find_by!(id: params[:user_id])
          user.maps.referenceable_by(current_user)
        end
    end
  end
end
