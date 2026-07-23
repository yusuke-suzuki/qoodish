module Journals
  class BookmarksController < ApplicationController
    before_action :authenticate_user!

    def create
      @journal = Journal.find_by!(id: params[:journal_id])

      raise Exceptions::Forbidden if current_user.author?(@journal)

      current_user.journal_bookmarks.create!(journal: @journal)
    end

    def destroy
      @journal = current_user.bookmarked_journals.find_by!(id: params[:journal_id])

      current_user.journal_bookmarks.find_by!(journal: @journal).destroy!
    end
  end
end
