module Me
  class JournalsController < ApplicationController
    before_action :authenticate_user!

    def show
      @journal = Journal
                 .preload(:bookmarks, user: :image)
                 .find_by!(user: current_user)
    end

    def update
      @journal = Journal.find_by!(user: current_user)
      @journal.revise!(user: current_user, **journal_params)
    end

    private

    def journal_params
      params.permit(:title, :description).to_h.symbolize_keys
    end
  end
end
