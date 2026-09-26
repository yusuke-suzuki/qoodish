module Admin
  class ReportsController < BaseController
    requires_permission Permission::READ_REPORTS, only: %i[index show]

    def index
      @reports = Report.pending.preload(:reporter).order(:created_at, :id)
    end

    def show
      @report = Report.find(params[:id])
    end
  end
end
