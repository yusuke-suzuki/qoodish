module Maps
  class ChaptersController < ApplicationController
    before_action :authenticate_user!

    def create
      map = current_user.referenceable_maps.find_by!(id: params[:map_id])
      journey = current_user.journeys.find_by!(id: params[:journey_id]) if params[:journey_id].present?

      @chapter = current_user.chapters.create!(chapter_params.merge(map: map, journey: journey))
    end

    private

    def chapter_params
      permitted = params.permit(:title)
      permitted[:content] = params[:content].permit!.to_h if params[:content].is_a?(ActionController::Parameters)
      permitted
    end
  end
end
