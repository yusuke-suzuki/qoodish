module Users
  class MapsController < ApplicationController
    before_action :authenticate_user!

    def index
      @maps =
        if params[:user_id] == current_user.uid
          if params[:following]
            current_user
              .following_maps
              .includes(:user, :reviews)
              .order(created_at: :desc)
          else
            current_user
              .maps
              .includes(:user, :reviews)
              .order(created_at: :desc)
          end
        else
          user = User.find_by!(id: params[:user_id])
          if params[:following]
            current_user
              .referenceable_maps
              .where(id: Map.following_by(user))
              .includes(:user, :reviews)
              .order(created_at: :desc)
          else
            current_user
              .referenceable_maps
              .where(id: user.maps)
              .includes(:user, :reviews)
              .order(created_at: :desc)
          end
        end
    end
  end
end
