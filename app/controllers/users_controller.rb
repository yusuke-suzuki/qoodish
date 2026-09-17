class UsersController < ApplicationController
  before_action :authenticate_user!, only: %i[index show]

  def index
    @users = if params[:q].present?
               User.search_by_name(params[:q]).preload(:image)
             else
               User.none
             end
  end

  def show
    @user = User.find_by!(id: params[:id])
  end

  def create
    payload = RequestContext.jwt_payload
    raise Exceptions::Unauthorized if payload.blank?

    @user = current_user || User.record!(
      uid: payload['sub'],
      name: payload['name']
    )

    @user.update!({ email: payload['email'], locale: RequestContext.locale }.compact_blank)
  end
end
