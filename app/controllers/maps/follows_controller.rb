module Maps
  class FollowsController < ApplicationController
    before_action :authenticate_user!

    def create
      ActiveRecord::Base.transaction do
        map = Map.includes(:user, :reviews).find_by!(id: params[:map_id])
        raise Exceptions::NotFound unless current_user.referenceable?(map)
        current_user.follow(map)
        @map = map.reload
        current_user.subscribe_topic("map_#{@map.id}")
        current_user.send_message_to_topic("map_#{@map.id}", "#{current_user.name} joined #{@map.name}.", "maps/#{@map.id}")
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
