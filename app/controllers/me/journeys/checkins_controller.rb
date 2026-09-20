module Me
  module Journeys
    class CheckinsController < ApplicationController
      before_action :authenticate_user!

      def create
        journey = current_user.journeys.find_by!(id: params[:journey_id])
        pin = current_user.referenceable_pins.find_by!(id: params[:pin_id] || params[:review_id])

        @checkin = journey.checkins.create!(checkin_params.merge(pin: pin))
      end

      def update
        journey = current_user.journeys.find_by!(id: params[:journey_id])

        @checkin = journey
                   .checkins
                   .preload(images: %i[pin_revision_images map_revision_images])
                   .find_by!(id: params[:id])
        @checkin.update!(checkin_params)
      end

      def destroy
        journey = current_user.journeys.find_by!(id: params[:journey_id])

        journey.checkins.find_by!(id: params[:id]).destroy!
      end

      private

      def checkin_params
        params.permit(:note, :checked_in_at, image_ids: [])
      end
    end
  end
end
