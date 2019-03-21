module Maps
  class CollaboratorsController < ApplicationController
    before_action :authenticate_user!

    def index
      @map = current_user.referenceable_maps.find_by!(id: params[:map_id])
      @collaborators = @map.followers
    end
  end
end
