class JournalsController < ApplicationController
  before_action :authenticate_user!

  def show
    @journal = Journal
               .not_blocking(current_user)
               .preload(:bookmarks, user: :image)
               .find_by!(id: params[:id])
  end
end
