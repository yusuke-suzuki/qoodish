class DevicesController < ApplicationController
  before_action :authenticate_user!
  before_action :require_sign_in!

  def create
    ActiveRecord::Base.transaction do
      if current_user.devices.exists?(registration_token: params[:registration_token])
        Rails.logger.info("Registration token #{params[:registration_token]} already exists.")
        return
      end

      Rails.logger.info("Create new registration token. registration_token: #{params[:registration_token]} uid: #{current_user.uid}")
      current_user.devices.create!(
        registration_token: params[:registration_token]
      )
      current_user.following_maps.each do |map|
        current_user.subscribe_topic("map_#{map.id}")
      end
      current_user.subscribe_topic("user_#{current_user.id}")
    end
  end

  def destroy
    device = current_user.devices.find_by(registration_token: params[:id])
    return if device.blank?

    Rails.logger.info("Create new registration token. registration_token: #{params[:id]} uid: #{current_user.uid}")
    device.destroy!
  end
end
