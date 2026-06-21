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
    ActiveRecord::Associations::Preloader.new(
      records: [current_user],
      associations: [:images]
    ).call

    current_user.update!(user_params)
    @user = current_user
  end

  def destroy
    current_user.reviews.preload(:images, :votes).load
    current_user.maps.preload(:images, :coauthorships, :bookmarks, :coauthorship_invitations, :votes, reviews: [:images, :votes]).load
    current_user.destroy!
  end

  private

  def user_params
    params.permit(:name, :biography, image_ids: [])
  end
end
