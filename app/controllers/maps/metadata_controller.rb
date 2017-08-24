module Maps
  class MetadataController < ApplicationController
    def show
      @map = Map.find_by!(id: params[:map_id], private: false)
    end
  end
end
