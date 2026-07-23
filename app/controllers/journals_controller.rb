class JournalsController < ApplicationController
  before_action :authenticate_user!

  def show
    @journal = Journal
               .preload(:bookmarks, user: :images)
               .find_by!(id: params[:id])
  end

  def update
    @journal = Journal.where(user: current_user).find_by!(id: params[:id])
    @journal.update!(journal_params)
  end

  private

  def journal_params
    params.permit(:title, :description)
  end
end
