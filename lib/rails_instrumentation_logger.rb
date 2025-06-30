# frozen_string_literal: true

require 'log_subscribers/action_controller_log_subscriber'
require 'log_subscribers/action_view_log_subscriber'
require 'log_subscribers/active_job_log_subscriber'

class RailsInstrumentationLogger
  class << self
    def setup!
      ActiveSupport.on_load(:action_dispatch) do
        ActionDispatch::LogSubscriber.detach_from :action_dispatch
      end
      ActiveSupport.on_load(:action_controller) do
        ActionController::LogSubscriber.detach_from :action_controller
      end
      ActiveSupport.on_load(:action_view) do
        ActionView::LogSubscriber.detach_from :action_view
      end
      ActiveSupport.on_load(:active_job) do
        ActiveJob::LogSubscriber.detach_from :active_job
      end

      LogSubscribers::ActionControllerLogSubscriber.attach_to :action_controller
      LogSubscribers::ActionViewLogSubscriber.attach_to :action_view
      LogSubscribers::ActiveJobLogSubscriber.attach_to :active_job
    end
  end
end
