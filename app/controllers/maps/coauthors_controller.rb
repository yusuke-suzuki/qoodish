module Maps
  class CoauthorsController < ApplicationController
    before_action :authenticate_user!

    def index
      @map = current_user.referenceable_maps.preload(user: :image).find_by(id: params[:map_id])
      @coauthors = @map ? [@map.user] + @map.coauthors.preload(:image).to_a : []
    end

    def destroy
      map = current_user.maps.find_by!(id: params[:map_id])
      map.coauthorships.find_by!(user_id: params[:id]).destroy!
    end
  end
end
