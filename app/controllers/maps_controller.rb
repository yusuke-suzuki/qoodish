class MapsController < ApplicationController
  before_action :authenticate_user!

  def index
    @maps = if params[:recommend]
              Map
                .public_open
                .not_bookmarked_by(current_user)
                .preload(:images, user: :images)
                .order(created_at: :desc)
                .sample(10)
            else
              current_user
                .related_maps
                .preload(:images, user: :images)
                .order(created_at: :desc)
            end
  end

  def show
    @map =
      current_user
      .referenceable_maps
      .preload(:images, user: :images)
      .find_by!(id: params[:id])
  end

  def create
    @map = current_user.maps.create!(map_params)

    ActiveRecord::Associations::Preloader.new(
      records: [@map],
      associations: :images
    ).call
  end

  def update
    @map = current_user.editable_maps.find_by!(id: params[:id])

    attributes = map_params
    attributes.delete(:private) unless current_user.map_author?(@map)
    @map.update!(attributes)

    ActiveRecord::Associations::Preloader.new(
      records: [@map],
      associations: :images
    ).call
  end

  def destroy
    current_user.maps.find_by!(id: params[:id]).destroy!
  end

  private

  def map_params
    params.permit(:name, :description, :private, :latitude, :longitude, image_ids: [])
  end
end
