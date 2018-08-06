class UsersController < ApplicationController
  before_action :authenticate_user!, only: [:index, :show, :destroy]
  before_action :require_sign_in!, only: [:index, :destroy]

  def index
    @users = []
    if params[:input].present?
      @users = User.where.not(id: current_user.id).where.like(name: "%#{params[:input]}%").limit(20)
    end
  end

  def show
    @user =
      if params[:id] == current_user.uid
        current_user
      else
        User.find_by!(id: params[:id])
      end
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
