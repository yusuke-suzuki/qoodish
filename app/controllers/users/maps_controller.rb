module Users
  class MapsController < ApplicationController
    before_action :authenticate_user!

    def index
      @maps =
        if params[:user_id] == current_user.uid
          if params[:following]
            current_user.following_maps.includes(:user, :reviews).order(created_at: :desc)
          else
            current_user.maps.includes(:user, :reviews).order(created_at: :desc)
          end
        else
          user = User.find_by!(id: params[:user_id])
          if params[:following]
            user.following_maps.referenceable_by(current_user)
          else
            user.maps.referenceable_by(current_user)
          end
        end
    end
  end
end
