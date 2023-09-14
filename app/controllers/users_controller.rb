class UsersController < ApplicationController
  before_action :authenticate_user!, only: %i[index show update destroy]
  before_action :require_sign_in!, only: %i[index update destroy]

  def index
    @users = []
    return unless params[:input].present?

    @users =
      User
      .where.not(id: current_user.id)
      .search_by_name(params[:input])
  end

  def show
    @user = if params[:id] == current_user.uid
              current_user
            else
              User.find_by!(id: params[:id])
            end
  end

  def create
    verifier = GoogleAuth.new
    verifier.verify_jwt(params[:token])

    @user = User.find_by(uid: params[:uid])
    return unless @user.blank?

    @user = User.create!(
      uid: params[:uid],
      name: params[:display_name],
      image_path: params[:image_url]
    )
  end

  def update
    current_user.name = params[:display_name] if params[:display_name].present?
    current_user.image_path = params[:image_url] if params[:image_url].present?
    current_user.biography = params[:biography]
    current_user.save!
    @user = current_user
  end

  def destroy
    current_user.destroy!
  end
end
