class UsersController < ApplicationController
  before_action :authenticate_user!, only: %i[index show update destroy]

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
    jwt = request.headers['Authorization'].split(' ', 2).last
    payload = verifier.verify_jwt(jwt)

    @user = User.find_by(uid: payload[:sub])
    return if @user.present?

    @user = User.create!(
      uid: payload['sub'],
      name: payload['name']
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
