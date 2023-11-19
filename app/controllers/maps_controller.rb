class MapsController < ApplicationController
  before_action :authenticate_user!

  def index
    @maps = if params[:recommend]
              Map
                .public_open
                .unfollowing_by(current_user)
                .preload(:user)
                .order(created_at: :desc)
                .sample(10)
            else
              current_user
                .following_maps
                .preload(:user)
                .order(created_at: :desc)
            end
  end

  def show
    @map =
      current_user
      .referenceable_maps
      .preload(:user)
      .find_by!(id: params[:id])
  end

  def create
    @map = current_user.maps.create!(map_params)
  end

  def update
    @map = current_user.maps.preload(:user).find_by!(id: params[:id])
    @map.update!(map_params)
  end

  def destroy
    current_user.maps.find_by!(id: params[:id]).destroy!
  end

  private

  def map_params
    params
      .permit(:name, :description, :private, :invitable, :shared, :latitude, :longitude, :image_url)
      .to_h
  end
end
