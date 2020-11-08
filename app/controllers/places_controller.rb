class PlacesController < ApplicationController
  before_action :authenticate_user!

  def index
    places_api = GooglePlaces::Client.new(ENV['GOOGLE_API_KEY_SERVER'])

    if params[:input].present?
      places =
        Rails.cache.fetch("places_predictions_by_input/#{I18n.locale}/#{params[:input]}", expires_in: 1.week) do
          Rails.logger.debug("Executing places predictions by input '#{params[:input]}' (#{I18n.locale})")
          places_api.predictions_by_input(params[:input], language: I18n.locale)
        end
    else
      places = places_api.spots(
        params[:lat],
        params[:lng],
        radius: 100,
        types: %w[restaurant cafe store aquarium bakery bar park spa zoo],
        language: I18n.locale
      ).map { |place| { description: place['name'], place_id: place['place_id'] } }
    end

    render json: places, status: :ok
  end
end
