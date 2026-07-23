class Guest::Users::ChaptersController < ApplicationController
  def index
    @chapters = Chapter
                .public_open
                .where(user_id: params[:user_id])
                .preload(:map, :images, user: %i[images journal])
                .order(created_at: :desc)
  end
end
