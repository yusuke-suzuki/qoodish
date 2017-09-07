class DevicesController < ApplicationController
  before_action :authenticate_user!

  def create
    ActiveRecord::Base.transaction do
      current_user.devices.find_or_create_by!(
        registration_token: params[:registration_token]
      )
      current_user.following_maps.each do |map|
        current_user.subscribe_topic("map_#{map.id}")
      end
    end
  end
end
