
module Maps
  class LikesController < ApplicationController
    before_action :authenticate_user!
    before_action :require_sign_in!, only: [:create, :destroy]

    def index
      map = Map.includes(:user, :reviews).find_by!(id: params[:map_id])
      raise Exceptions::NotFound unless current_user.referenceable?(map)
      @likes = map.get_likes
    end

    def create
      @map = Map.includes(:user, :reviews).find_by!(id: params[:map_id])
      raise Exceptions::NotFound unless current_user.referenceable?(@map)

      ActiveRecord::Base.transaction do
        @map.liked_by(current_user)
        Notification.create!(
          notifiable: @map,
          notifier: current_user,
          recipient: @map.user,
          key: 'liked'
        )
      end

      data = {
        notification_type: 'like_map',
        map_id: @map.id
      }
      current_user.send_message_to_topic(
        "user_#{@map.user.id}",
        "#{current_user.name} liked your map.",
        "maps/#{@map.id}",
        @map.thumbnail_url,
        data
      )
    end

    def destroy
      @map = Map.includes(:user, :reviews).find_by!(id: params[:map_id])
      raise Exceptions::NotFound unless current_user.referenceable?(@map)
      @map.unliked_by(current_user)
    end
  end
end
