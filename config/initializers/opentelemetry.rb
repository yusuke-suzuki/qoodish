# frozen_string_literal: true

require 'opentelemetry/sdk'
require 'opentelemetry/instrumentation/all'
require 'google_cloud_log_formatter'

OpenTelemetry.logger = ActiveSupport::Logger.new($stdout)
                                            .tap do |logger|
  logger.formatter = GoogleCloudLogFormatter.new
end

OpenTelemetry::SDK.configure do |c|
  c.use_all
end
