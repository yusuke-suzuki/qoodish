module Maps
  class FollowsController < ApplicationController
    before_action :authenticate_user!

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
        current_user.subscribe_topic("map_#{@map.id}")
        data = {
          notification_type: 'follow_map',
          map_id: @map.id
        }
        current_user.send_message_to_topic(
          "user_#{@map.user.id}",
          "#{current_user.name} followed #{@map.name}.",
          "maps/#{@map.id}",
          @map.thumbnail_url,
          data
        )
      end
    end

    def destroy
      ActiveRecord::Base.transaction do
        map = Map.includes(:user, :reviews).find_by!(id: params[:map_id])
        raise Exceptions::MapOwnerCannotRemoved if current_user.map_owner?(map)
        current_user.stop_following(map)
        @map = map.reload
        current_user.unsubscribe_topic("map_#{@map.id}")
      end
    end
  end
end
