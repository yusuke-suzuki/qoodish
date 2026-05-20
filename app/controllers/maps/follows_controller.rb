module Maps
  class FollowsController < ApplicationController
    before_action :authenticate_user!

    def create
      @map = if params[:invite_id]
               invite = current_user.invites.find_by!(id: params[:invite_id], expired: false)
               invite.update!(expired: true)
               invite.invitable
             else
               current_user
                 .referenceable_maps
                 .find_by!(id: params[:map_id])
             end

      current_user.follow!(@map)

      preload_map_for_serialization
    end

    def destroy
      @map =
        current_user
        .following_maps
        .find_by!(id: params[:map_id])

      raise Exceptions::MapOwnerCannotRemoved if current_user.map_owner?(@map)

      current_user.unfollow!(@map)

      preload_map_for_serialization
    end

    private

    def preload_map_for_serialization
      ActiveRecord::Associations::Preloader.new(
        records: [@map],
        associations: [:images, { user: :images }]
      ).call
    end

    def follow_params
      params
        .permit(:map_id, :invite_id)
        .to_h
    end
  end
end
