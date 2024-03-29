module Maps
  class FollowsController < ApplicationController
    before_action :authenticate_user!

    def create
      map = if params[:invite_id]
              invite = current_user.invites.find_by!(id: params[:invite_id], expired: false)
              invite.update!(expired: true)
              invite.invitable
            else
              current_user
                .referenceable_maps
                .preload(:user)
                .find_by!(id: params[:map_id])
            end

      current_user.follow!(map)

      @map = map.reload
    end

    def destroy
      map =
        current_user
        .following_maps
        .preload(:user)
        .find_by!(id: params[:map_id])

      raise Exceptions::MapOwnerCannotRemoved if current_user.map_owner?(map)

      current_user.unfollow!(map)

      @map = map.reload
    end

    def follow_params
      params
        .permit(:map_id, :invite_id)
        .to_h
    end
  end
end
