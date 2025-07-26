class UsersController < ApplicationController
  before_action :authenticate_user!, only: %i[show update destroy]

  def show
    @user = if params[:id] == current_user.uid
              current_user
            else
              User.find_by!(id: params[:id])
            end
  end

  def create
    if current_user
      @user = current_user
      return
    end

    payload = RequestContext.jwt_payload
    raise Exceptions::Unauthorized if payload.blank?

    @user = User.create!(
      uid: payload['sub'],
      name: payload['name']
    )
  end

  def update
    current_user.update!(user_params)
    @user = current_user
  end

  def destroy
    current_user.destroy!
  end

  private

  def user_params
    params
      .permit(:name, :biography, :image_path)
      .to_h
  end
end
