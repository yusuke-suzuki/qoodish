class UsersController < ApplicationController
  before_action :authenticate_user!, only: [:destroy]

  def create
    auth_client = Firebase::Auth.new
    auth_client.verify_id_token(params['user']['token'])

    @user = User.find_by(
      provider: params['user']['provider'],
      provider_uid: params['user']['provider_uid']
    )
    if @user.present?
      @user.update!(
        uid: params['user']['uid'],
        email: params['user']['email'],
        token: params['user']['provider_token'],
        name: params['user']['display_name']
      )
    else
      @user = User.create!(
        uid: params['user']['uid'],
        provider: params['user']['provider'],
        provider_uid: params['user']['provider_uid'],
        email: params['user']['email'],
        token: params['user']['provider_token'],
        name: params['user']['display_name']
      )
    end
    @user.upload_profile_image(params['user']['photo_url'])
  rescue => ex
    Rails.logger.info(ex)
    raise Exceptions::Unauthorized
  end

  def destroy
    current_user.destroy!
  end
end
