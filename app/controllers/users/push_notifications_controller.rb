module Users
  class PushNotificationsController < ApplicationController
    before_action :authenticate_user!

    def create
      ActiveRecord::Base.transaction do
        unless current_user.devices.exists?(registration_token: params[:registration_token])
          current_user.devices.create!(
            registration_token: params[:registration_token]
          )
        end

        current_user.following_maps.each do |map|
          current_user.subscribe_topic("map_#{map.id}")
        end
        current_user.subscribe_topic("user_#{current_user.id}")

        current_user.push_enabled = true
        current_user.save!
      end
    end

    def destroy
      ActiveRecord::Base.transaction do
        current_user.push_enabled = false
        current_user.save!
        current_user.unfollow_all_maps
        current_user.unsubscribe_topic("user_#{current_user.id}")
      end
    end
  end
end
