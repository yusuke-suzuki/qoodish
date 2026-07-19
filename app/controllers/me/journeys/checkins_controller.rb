module Me
  module Journeys
    class CheckinsController < ApplicationController
      before_action :authenticate_user!

      def create
        journey = current_user.journeys.find_by!(id: params[:journey_id])
        review = current_user.referenceable_reviews.find_by!(id: params[:review_id])

        @checkin = journey.checkins.create!(checkin_params.merge(review: review))
      end

      def update
        journey = current_user.journeys.find_by!(id: params[:journey_id])

        @checkin = journey.checkins.find_by!(id: params[:id])
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
