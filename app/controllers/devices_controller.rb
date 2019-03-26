class DevicesController < ApplicationController
  before_action :authenticate_user!
  before_action :require_sign_in!

  def update
    current_user.devices.find_or_create_by(
      registration_token: params[:id]
    )
  end

  def destroy
    device = current_user.devices.find_by(registration_token: params[:id])
    return if device.blank?

    device.destroy!
    Rails.logger.debug("Deleted registration token: #{params[:id]} uid: #{current_user.uid}")
  end
end
