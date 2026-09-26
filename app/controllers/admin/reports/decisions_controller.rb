module Admin
  module Reports
    class DecisionsController < BaseController
      requires_permission Permission::DECIDE_REPORTS, only: :create

      def create
        report = Report.find(params[:report_id])

        @decision = report.decide!(staff_member: current_staff_member, **decision_params)

        render status: :created
      end

      private

      def decision_params
        params.permit(:outcome, :reason).to_h.symbolize_keys
      end
    end
  end
end
