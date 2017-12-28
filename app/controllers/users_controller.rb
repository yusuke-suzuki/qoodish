class UsersController < ApplicationController
  before_action :authenticate_user!, only: [:show, :destroy]

  def show
    @user = User.find_by!(uid: params[:id])
  end

  def create
    Rails.logger.info(params)
    auth_client = Firebase::Auth.new
    auth_client.verify_id_token(params[:user][:token])

    @user = User.find_by(
      provider: params[:user][:provider],
      provider_uid: params[:user][:provider_uid]
    )
    @user =
      if @user.present?
        update_user
      else
        create_user
      end
    @user.upload_profile_image(params[:user][:photo_url])
  end

  def destroy
    ActiveRecord::Base.transaction do
      current_user.unfollow_all_maps
      current_user.unsubscribe_topic("user_#{current_user.id}")
      current_user.destroy!
    end
  end

  private

  def create_user
    @user = User.create!(
      uid: params[:user][:uid],
      provider: params[:user][:provider],
      provider_uid: params[:user][:provider_uid],
      email: params[:user][:email],
      provider_token: params[:user][:provider_token],
      name: params[:user][:display_name]
    )
  end

  def update_user
    @user.update!(
      uid: params[:user][:uid],
      email: params[:user][:email],
      provider_token: params[:user][:provider_token],
      name: params[:user][:display_name]
    )
    @user
  end
end
