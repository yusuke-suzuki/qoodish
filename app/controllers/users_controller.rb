class UsersController < ApplicationController
  before_action :authenticate_user!, only: [:index, :show, :update, :destroy]
  before_action :require_sign_in!, only: [:index, :update, :destroy]

  def index
    @users = []
    if params[:input].present?
      @users = User.where.not(id: current_user.id).where('name LIKE ?', "%#{params[:input]}%").limit(20)
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

    @user = User.find_by(uid: params[:user][:uid])
    if @user.blank?
      @user = User.create!(
        uid: params[:user][:uid],
        name: params[:user][:display_name],
        image_path: params[:user][:photo_url]
      )
    end
  end

  def update
    current_user.name = params[:display_name] if params[:display_name].present?
    current_user.image_path = params[:image_url] if params[:image_url].present?
    current_user.biography = params[:biography]
    current_user.save!
    @user = current_user
  end

  def destroy
    ActiveRecord::Base.transaction do
      current_user.unfollow_all_maps
      current_user.unsubscribe_topic("user_#{current_user.id}")
      current_user.destroy!
    end
  end
end
