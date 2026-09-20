class Guest::Maps::CoauthorsController < ApplicationController
  def index
    @map = Map.public_open.preload(user: :image).find_by(id: params[:map_id])
    @coauthors = @map ? [@map.user] + @map.coauthors.preload(:image).to_a : []
  end
end
