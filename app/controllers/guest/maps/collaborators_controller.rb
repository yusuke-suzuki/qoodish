class Guest::Maps::CollaboratorsController < ApplicationController
  def index
    map = Map.public_open.find_by(id: params[:map_id])
    @collaborators = map ? map.followers : []
  end
end
