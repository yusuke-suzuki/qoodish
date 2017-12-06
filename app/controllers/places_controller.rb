class PlacesController < ApplicationController
  before_action :authenticate_user!

  def index
    places_api = GooglePlaces::Client.new(ENV['GOOGLE_API_KEY_SERVER'])
    if params[:input].present?
      places = places_api.predictions_by_input(params[:input], language: I18n.locale)
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
