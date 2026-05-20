class Guest::MapsController < ApplicationController
  def show
    @map = Map
           .public_open
           .preload(:images, user: :images)
           .find_by!(id: params[:id])
  end

  def index
    @maps = if params[:input].present?
              Map
                .public_open
                .preload(:images, user: :images)
                .search_by_words(params[:input].strip.split(/[[:blank:]]+/))
                .order(created_at: :desc)
                .limit(20)
            elsif params[:recent].present?
              Map
                .public_open
                .preload(:images, user: :images)
                .order(created_at: :desc)
                .limit(12)
            elsif params[:active]
              Map
                .public_open
                .preload(:images, user: :images)
                .active
            elsif params[:popular]
              Map
                .public_open
                .preload(:images, user: :images)
                .popular
            elsif params[:recommend]
              Map
                .public_open
                .preload(:images, user: :images)
                .order(created_at: :desc)
                .sample(10)
            else
              raise Exceptions::BadRequest
            end
  end
end
