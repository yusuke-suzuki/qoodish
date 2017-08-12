module Maps
  class CollaboratorsController < ApplicationController
    before_action :authenticate_user!

    def index
      @map = Map.find_by!(id: params[:map_id])
      raise Exceptions::NotFound unless current_user.referenceable?(@map)
      @collaborators = @map.followers
    end
  end
end
