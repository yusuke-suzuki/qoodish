class InappropriateContentsController < ApplicationController
  before_action :authenticate_user!

  def create
    @inappropriate = InappropriateContent.create!(
      content_id_val: params[:content_id],
      content_type: params[:content_type],
      reason_id_val: params[:reason_id],
      user_id: current_user.id
    )
  end
end
