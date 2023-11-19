class InappropriateContentsController < ApplicationController
  before_action :authenticate_user!

  def create
    InappropriateContent.create!(
      content_id_val: params[:content_id],
      content_type: params[:content_type],
      reason_id_val: params[:reason_id],
      user_id: current_user.id
    )
  end

  def create_params
    params
      .permit(:content_id, :content_type, :reason_id)
      .to_h { |key, value| [key == :content_id ? :content_id_val : key, value] }
      .to_h { |key, value| [key == :reason_id ? :reason_id_val : key, value] }
  end
end
