class DevicesController < ApplicationController
  before_action :authenticate_user!

  def create
    @current_user.devices.find_or_create_by!(
      registration_token: params[:registration_token]
    )
  end
end
