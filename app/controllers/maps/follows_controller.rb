module Maps
  class FollowsController < ApplicationController
    before_action :authenticate_user!

    def create
      map = Map.includes(:user, :reviews).find_by!(id: params[:map_id])
      raise Exceptions::NotFound unless current_user.referenceable?(map)
      current_user.follow(map)
      @map = map.reload
    end

    def destroy
      map = Map.includes(:user, :reviews).find_by!(id: params[:map_id])
      raise Exceptions::MapOwnerCannotRemoved if current_user.map_owner?(map)
      current_user.stop_following(map)
      @map = map.reload
    end
  end
end
