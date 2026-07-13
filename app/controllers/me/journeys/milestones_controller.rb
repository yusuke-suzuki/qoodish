module Me
  module Journeys
    class MilestonesController < ApplicationController
      before_action :authenticate_user!

      def create
        journey = current_user.journeys.unfinished.find_by!(id: params[:journey_id])
        review = current_user.referenceable_reviews.find_by!(id: params[:review_id])

        @milestone = journey.milestones.create!(review: review)
      end

      def destroy
        journey = current_user.journeys.unfinished.find_by!(id: params[:journey_id])

        journey.milestones.find_by!(id: params[:id]).destroy!
      end
    end
  end
end
