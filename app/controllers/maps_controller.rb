class MapsController < ApplicationController
  before_action :authenticate_user!

  def index
    @maps = if params[:recommend]
              Map
                .public_open
                .unfollowing_by(current_user)
                .with_deps
                .order(created_at: :desc)
                .sample(10)
            else
              current_user
                .following_maps
                .with_deps
                .order(created_at: :desc)
            end
  end

  def show
    @map =
      current_user
      .referenceable_maps
      .with_deps
      .find_by!(id: params[:id])
  end

  def create
    Rails.logger.info(create_params)
    @map = current_user.maps.create!(create_params)
  end

  def update
    @map = current_user.maps.includes(%i[votes voters]).find_by!(id: params[:id])
    @map.update!(attributes_for_update) if attributes_for_update.present?
  end

  def destroy
    current_user.maps.find_by!(id: params[:id]).destroy!
  end

  private

  def create_params
    params
      .permit(:name, :description, :private, :invitable, :shared, :base_id, :base_name, :image_url)
      .to_h { |key, value| [key == :base_id ? :base_id_val : key, value] }
  end

  def attributes_for_update
    attributes = {}
    attributes[:name] = params[:name] if params[:name]
    attributes[:description] = params[:description] if params[:description]
    attributes[:private] = params[:private] unless params[:private].nil?
    attributes[:base_id_val] = params[:base_id] if params[:base_id]
    attributes[:base_name] = params[:base_name] if params[:base_name]
    attributes[:invitable] = params[:invitable] unless params[:invitable].nil?
    attributes[:shared] = params[:shared] unless params[:shared].nil?
    attributes[:image_url] = params[:image_url] if params[:image_url].present?
    attributes
  end
end
