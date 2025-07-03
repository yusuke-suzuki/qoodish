# frozen_string_literal: true

require 'json'
require 'logger'

# Google Cloud Logging で推奨される構造化ログにフォーマットするためのクラス
# https://cloud.google.com/logging/docs/structured-logging
class GoogleCloudLogFormatter < Logger::Formatter
  IGNORE_PATHS = [
    %r{/bundle/vendor/ruby/},
    %r{/usr/local/bundle/gems/},
    /lib\/trace_context_middleware\.rb/
  ].freeze

  SEVERITY_MAP = {
    'DEBUG' => 'DEBUG',
    'INFO' => 'INFO',
    'WARN' => 'WARNING',
    'ERROR' => 'ERROR',
    'FATAL' => 'CRITICAL',
    'UNKNOWN' => 'DEFAULT'
  }.freeze

  def call(severity, timestamp, _progname, msg)
    base_entry = build_base_entry(severity, timestamp)
    message_data = format_message(msg)

    source_location = caller_locations.find do |location|
      !IGNORE_PATHS.any? { |pattern| location.path.match?(pattern) }
    end
    context_data = build_request_context(source_location)

    log_entry = base_entry
                .merge(message_data)
                .merge(context_data)

    "#{log_entry.to_json}\n"
  end

  private

  def build_base_entry(severity, timestamp)
    entry = {
      time: timestamp,
      severity: SEVERITY_MAP[severity] || 'DEFAULT'
    }

    entry
  end

  def format_message(message)
    if message.is_a?(Hash)
      format_hash(message)
    elsif message.is_a?(Exception)
      format_exception(message)
    elsif message.is_a?(String)
      { message: message }
    else
      { message: message.inspect }
    end
  end

  def format_hash(message)
    # ハッシュから例外オブジェクトを抽出・変換し、ハッシュにマージし直して返す
    error = message[:error] || message[:e]

    if error.is_a?(Exception)
      format_exception(error).merge(message.except(:error))
    else
      # message キーの有無はチェックせず、ハッシュのまま返す
      message
    end
  end

  # 例外オブジェクトを構造化ログに展開して返す
  def format_exception(exception)
    return {} unless exception.is_a?(Exception)

    {
      message: exception.message,
      stack_trace: exception.backtrace&.join("\n")
    }
  end

  def build_request_context(source_location = nil) # rubocop:disable Metrics/MethodLength
    result = {}

    if source_location
      result['logging.googleapis.com/sourceLocation'] = {
        file: source_location.path,
        line: source_location.lineno,
        function: source_location.base_label
      }
    end

    trace_context = Thread.current[:trace_context]

    if trace_context
      trace_id, span_id = trace_context.split(';').first.split('/')
      result['logging.googleapis.com/trace'] = "projects/#{ENV['GOOGLE_PROJECT_ID']}/traces/#{trace_id}"
      result['logging.googleapis.com/spanId'] = span_id
      result['logging.googleapis.com/trace_sampled'] = true
    end

    user_id = Thread.current[:user_id]

    result[:user_id] = Thread.current[:user_id] if user_id

    result[:source_location] = "#{source_location.path}:#{source_location.lineno}" if source_location

    result
  end
end
