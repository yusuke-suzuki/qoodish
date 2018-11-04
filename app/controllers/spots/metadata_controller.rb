module Spots
  class MetadataController < ApplicationController
    def show
      @spot = Spot.new(params[:id])
    end
  end
end
