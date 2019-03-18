module Maps
  class FollowsController < ApplicationController
    before_action :authenticate_user!
    before_action :require_sign_in!

    def create
      ActiveRecord::Base.transaction do
        if params[:invite_id]
          invite = current_user.invites.find_by!(id: params[:invite_id], expired: false)
          invite.update!(expired: true)
          map = invite.invitable
        else
          map = Map.includes(:user, :reviews).find_by!(id: params[:map_id])
          raise Exceptions::NotFound unless current_user.referenceable?(map)
        end
        current_user.follow(map)
        @map = map.reload
        Notification.create!(
          notifiable: @map,
          notifier: current_user,
          recipient: @map.user,
          key: 'followed'
        )
      end
    end

    def destroy
      ActiveRecord::Base.transaction do
        map = Map.includes(:user, :reviews).find_by!(id: params[:map_id])
        raise Exceptions::MapOwnerCannotRemoved if current_user.map_owner?(map)

        current_user.stop_following(map)
        @map = map.reload
      end
    end
  end
end
