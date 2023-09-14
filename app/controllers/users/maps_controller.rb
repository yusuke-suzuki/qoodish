module Users
  class MapsController < ApplicationController
    before_action :authenticate_user!

    def index
      @maps = if params[:user_id] == current_user.uid
                if params[:following]
                  current_user
                    .following_maps
                    .includes(%i[user votes voters])
                    .order(created_at: :desc)
                else
                  current_user
                    .maps
                    .includes(%i[votes voters])
                    .order(created_at: :desc)
                end
              else
                user = User.find_by!(id: params[:user_id])
                if params[:following]
                  current_user
                    .referenceable_maps
                    .with_deps
                    .where(id: Map.following_by(user))
                    .order(created_at: :desc)
                else
                  current_user
                    .referenceable_maps
                    .with_deps
                    .where(id: user.maps)
                    .order(created_at: :desc)
                end
              end
    end
  end
end
