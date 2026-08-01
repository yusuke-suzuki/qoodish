class UsersController < ApplicationController
  before_action :authenticate_user!, only: %i[index show]

  def index
    @users = if params[:q].present?
               User.search_by_name(params[:q]).preload(:images)
             else
               User.none
             end
  end

  def show
    @user = User.find_by!(id: params[:id])
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
end
