class RailsInstrumentationLogger
  def self.setup!
    subscribe_to_controller_events
    subscribe_to_database_events
  end

  class << self
    private

    def subscribe_to_controller_events
      ActiveSupport::Notifications.subscribe('start_processing.action_controller') do |_name, _start, _finish, _id, payload|
        Rails.logger.info({
                            message: "Started #{payload[:method]} \"#{payload[:path]}\"",
                            event_type: 'controller_start',
                            controller: payload[:controller],
                            action: payload[:action],
                            params: filter_params(payload[:params]),
                            format: payload[:format],
                            method: payload[:method],
                            path: payload[:path]
                          })
      end

      ActiveSupport::Notifications.subscribe('process_action.action_controller') do |_name, start, finish, _id, payload|
        duration_in_ms = (finish - start) * 1000
        Rails.logger.info({
                            message: "Completed #{payload[:status]} in #{duration_in_ms.round(2)}ms",
                            event_type: 'controller_complete',
                            controller: payload[:controller],
                            action: payload[:action],
                            status: payload[:status],
                            duration: "#{duration_in_ms.round(2)}ms",
                            view_runtime: payload[:view_runtime] ? "#{payload[:view_runtime].round(2)}ms" : nil,
                            db_runtime: payload[:db_runtime] ? "#{payload[:db_runtime].round(2)}ms" : nil,
                            allocations: payload[:allocations]
                          })
      end
    end

    def subscribe_to_database_events
      ActiveSupport::Notifications.subscribe('sql.active_record') do |_name, start, finish, _id, payload|
        # 内部的な SQL クエリ (スキーマなど) は除外
        next if payload[:name] == 'SCHEMA' || payload[:sql].include?('SHOW ')

        duration_in_ms = (finish - start) * 1000
        Rails.logger.info({
                            message: "#{payload[:name]} (#{duration_in_ms.round(2)}ms)",
                            event_type: 'database_query',
                            sql: payload[:sql],
                            name: payload[:name],
                            duration: "#{duration_in_ms.round(2)}ms",
                            connection_id: payload[:connection_id]
                          })
      end
    end

    def filter_params(params)
      return {} unless params

      filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
      filter.filter(params)
    end
  end
end
