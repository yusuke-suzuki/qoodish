class DevicesController < ApplicationController
  before_action :authenticate_user!

  def create
    ActiveRecord::Base.transaction do
      return if current_user.devices.exists?(registration_token: params[:registration_token])

      current_user.devices.create!(
        registration_token: params[:registration_token]
      )
      current_user.following_maps.each do |map|
        current_user.subscribe_topic("map_#{map.id}")
      end
    end
  end
end
