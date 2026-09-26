class ReportsController < ApplicationController
  before_action :authenticate_user!

  def create
    moderatable = Report.moderatable_for(params[:moderatable_type], params[:moderatable_id], current_user)

    @report = Report.file!(report_params.merge(moderatable: moderatable, reporter: current_user))

    render status: :created
  end

  private

  def report_params
    params.permit(:category, :details)
  end
end
