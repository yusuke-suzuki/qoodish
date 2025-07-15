# frozen_string_literal: true

module LogSubscribers
  class ActionControllerLogSubscriber < ActiveSupport::LogSubscriber
    INTERNAL_PARAMS = %w[controller action format _method only_path].freeze

    def start_processing(event)
      payload = event.payload

      Rails.logger.info({
                          message: "Processing by #{payload[:controller]}##{payload[:action]} as #{payload[:format].to_s.upcase}",
                          event_type: event.name,
                          controller: payload[:controller],
                          action: payload[:action],
                          params: filter_params(payload[:params]),
                          format: payload[:format],
                          method: payload[:method],
                          path: payload[:path]
                        })
    end

    def process_action(event)
      payload = event.payload

      Rails.logger.info({
                          message: "Completed #{payload[:status]} #{Rack::Utils::HTTP_STATUS_CODES[payload[:status]]}",
                          event_type: event.name,
                          duration: event.duration,
                          gc_time: event.gc_time,
                          controller: payload[:controller],
                          action: payload[:action],
                          params: filter_params(payload[:params]),
                          format: payload[:format],
                          method: payload[:method],
                          path: payload[:path],
                          request: payload[:request],
                          response: payload[:response],
                          status: payload[:status],
                          view_runtime: payload[:view_runtime],
                          db_runtime: payload[:db_runtime]
                        })
    end

    def send_file(event)
      payload = event.payload

      Rails.logger.info({
                          message: "Sent file #{payload[:path]}",
                          event_type: event.name,
                          duration: event.duration,
                          path: payload[:path]
                        })
    end

    def send_data(event)
      payload = event.payload

      Rails.logger.info({
        message: "Sent data #{payload[:filename]}",
        event_type: event.name,
        duration: event.duration
      }.merge(payload))
    end

    def redirect_to(event)
      payload = event.payload

      Rails.logger.info({
                          message: "Redirected to #{payload[:location]}",
                          event_type: event.name,
                          status: payload[:status],
                          location: payload[:location]
                        })
    end

    def halted_callback(event)
      payload = event.payload

      Rails.logger.info({
                          message: "Filter chain halted as #{payload[:filter].inspect} rendered or redirected",
                          event_type: event.name,
                          filter: payload[:filter]
                        })
    end

    def unpermitted_parameters(event)
      payload = event.payload

      Rails.logger.warn({
                          message: "Unpermitted parameter(s) for #{payload[:context][:controller]}##{payload[:context][:action]}: #{payload[:keys].join(', ')}",
                          event_type: event.name,
                          keys: payload[:keys],
                          context: {
                            controller: payload[:context][:controller],
                            action: payload[:context][:action],
                            params: filter_params(payload[:context][:params])
                          }
                        })
    end

    private

    def filter_params(params)
      return {} unless params

      filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
      filter.filter(params.except(*INTERNAL_PARAMS))
    end
  end
end
