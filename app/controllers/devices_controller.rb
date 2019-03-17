class DevicesController < ApplicationController
  before_action :authenticate_user!
  before_action :require_sign_in!

  def create
    ActiveRecord::Base.transaction do
      if current_user.devices.exists?(registration_token: params[:registration_token])
        Rails.logger.info("Registration token #{params[:registration_token]} already exists.")
        return
      end

      current_user.devices.create!(
        registration_token: params[:registration_token]
      )
      Rails.logger.info("Create new registration token. registration_token: #{params[:registration_token]} uid: #{current_user.uid}")
    end
  end

  def destroy
    ActiveRecord::Base.transaction do
      device = current_user.devices.find_by(registration_token: params[:id])
      return if device.blank?

      device.destroy!
      Rails.logger.info("Deleted registration token: #{params[:id]} uid: #{current_user.uid}")
    end
  end
end
