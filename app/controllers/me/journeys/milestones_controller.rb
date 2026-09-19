module Me
  module Journeys
    class MilestonesController < ApplicationController
      before_action :authenticate_user!

      def create
        journey = current_user.journeys.unfinished.find_by!(id: params[:journey_id])
        pin = current_user.referenceable_pins.find_by!(id: params[:pin_id] || params[:review_id])

        @milestone = journey.milestones.create!(pin: pin)
      end

      def destroy
        journey = current_user.journeys.unfinished.find_by!(id: params[:journey_id])

        journey.milestones.find_by!(id: params[:id]).destroy!
      end
    end
  end
end
