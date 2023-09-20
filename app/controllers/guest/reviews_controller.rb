class Guest::ReviewsController < ApplicationController
  def show
    @review = Review
              .public_open
              .includes(:map, :user, :images, { spot: :place }, { comments: :user })
              .find_by!(id: params[:id])
  end

  def index
    @reviews = if params[:recent]
                 Review
                   .public_open
                   .limit(8)
                   .preload(:map, :user, :images, { spot: :place }, { comments: :user })
                   .order(created_at: :desc)
               elsif params[:popular]
                 Review
                   .public_open
                   .popular
                   .preload(:map, :user, :images, { spot: :place }, { comments: :user })
               else
                 raise Exceptions::BadRequest
               end
  end
end
