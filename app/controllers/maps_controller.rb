class MapsController < ApplicationController
  before_action :authenticate_user!

  def index
    @maps =
      if params[:popular]
        Map.popular
      elsif params[:postable]
        current_user.following_maps.postable(current_user)
      else
        current_user.following_maps.includes(:user, :reviews).order(created_at: :desc)
      end
  end

  def show
    @map = Map.includes(:user, :reviews).find_by!(id: params[:id])
    raise Exceptions::NotFound if @map.private && !current_user.following?(@map)
  end

  def create
    ActiveRecord::Base.transaction do
      @map = current_user.maps.create!(
        name: params[:name],
        description: params[:description],
        private: params[:private],
        invitable: params[:invitable],
        shared: params[:shared],
        base_id_val: params[:base_id],
        base_name: params[:base_name]
      )
      current_user.follow(@map)
      current_user.subscribe_topic("map_#{@map.id}")
    end
  end

  def update
    @map = current_user.maps.find_by!(id: params[:id])
    @map.update!(attributes_for_update) if attributes_for_update.present?
  end

  def destroy
    ActiveRecord::Base.transaction do
      map = current_user.maps.find_by!(id: params[:id])
      current_user.unsubscribe_topic("map_#{map.id}")
      current_user.stop_following(map)
      map.destroy!
    end
  end

  private

  def attributes_for_update
    attributes = {}
    attributes[:name] = params[:name] if params[:name]
    attributes[:description] = params[:description] if params[:description]
    attributes[:private] = params[:private] unless params[:private].nil?
    attributes[:base_id_val] = params[:base_id] if params[:base_id]
    attributes[:base_name] = params[:base_name] if params[:base_name]
    attributes[:invitable] = params[:invitable] unless params[:invitable].nil?
    attributes[:shared] = params[:shared] unless params[:shared].nil?
    attributes
  end
end
