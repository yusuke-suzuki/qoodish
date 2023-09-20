class Guest::MapsController < ApplicationController
  def show
    @map = Map
           .public_open
           .includes(:user, :reviews)
           .find_by!(id: params[:id])
  end

  def index
    @maps = if params[:input].present?
              Map
                .public_open
                .preload(:user, :reviews)
                .search_by_words(params[:input].strip.split(/[[:blank:]]+/))
                .order(created_at: :desc)
                .limit(20)
            elsif params[:recent].present?
              Map
                .public_open
                .preload(:user, :reviews)
                .order(created_at: :desc)
                .limit(12)
            elsif params[:active]
              Map
                .public_open
                .preload(:user, :reviews)
                .active
            elsif params[:popular]
              Map
                .public_open
                .preload(:user, :reviews)
                .popular
            elsif params[:recommend]
              Map
                .public_open
                .preload(:user, :reviews)
                .order(created_at: :desc)
                .sample(10)
            else
              raise Exceptions::BadRequest
            end
  end
end
