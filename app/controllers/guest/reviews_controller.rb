class Guest::ReviewsController < ApplicationController
  def show
    @review = Review
              .public_open
              .preload(:map, { user: :images }, :images, { comments: { user: :images } })
              .find_by!(id: params[:id])
  end

  def index
    @reviews = if params[:recent]
                 Review
                   .public_open
                   .limit(8)
                   .preload(:map, { user: :images }, :images, { comments: { user: :images } })
                   .order(created_at: :desc)
               elsif params[:popular]
                 Review
                   .public_open
                   .popular
                   .preload(:map, { user: :images }, :images, { comments: { user: :images } })
               else
                 raise Exceptions::BadRequest
               end
  end
end
