module Spots
  class MetadataController < ApplicationController
    def show
      @spot = Spot.new(params[:spot_id])
    end
  end
end
