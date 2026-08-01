class JournalsController < ApplicationController
  before_action :authenticate_user!

  def show
    @journal = Journal
               .preload(:bookmarks, user: :images)
               .find_by!(id: params[:id])
  end
end
