module Reviews
  class MetadataController < ApplicationController
    def show
      @review = Review
                .left_outer_joins(:map)
                .find_by!(maps: { private: false }, reviews: { id: params[:review_id] })
    end
  end
end
