# frozen_string_literal: true

require 'json'
require 'logger'
require 'request_context'

# Google Cloud Logging で推奨される構造化ログにフォーマットするためのクラス
# https://cloud.google.com/logging/docs/structured-logging
class GoogleCloudLogFormatter < Logger::Formatter
  IGNORE_SOURCE_PATHS = [
    %r{/bundle/vendor/ruby/},
    %r{/usr/local/bundle/gems/},
    %r{lib/request_context_middleware\.rb}
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

    source_location = find_source_location if high_severity?(severity)
    context_data = build_request_context(source_location)

    log_entry = base_entry
                .merge(message_data)
                .merge(context_data)

    "#{log_entry.to_json}\n"
  end

  private

  def high_severity?(severity)
    %w[ERROR FATAL].include?(severity)
  end

  def find_source_location
    caller_locations.find do |location|
      IGNORE_SOURCE_PATHS.none? { |pattern| location.path.match?(pattern) }
    end
  end

  def build_base_entry(severity, timestamp)
    {
      time: timestamp.utc.rfc3339(9),
      severity: SEVERITY_MAP[severity] || 'DEFAULT',
      'logging.googleapis.com/labels' => { component: 'rails' }
    }
  end

  def format_message(message)
    case message
    when Hash
      format_hash(message)
    when Exception
      format_exception(message)
    when String
      { message: message }
    else
      { message: message.inspect }
    end
  end

  def format_hash(message)
    # :msg キーが存在する場合、Google Cloud Log Explorer が解釈できるよう
    # :message キーに値を移し替える
    message[:message] = message.delete(:msg) if message.key?(:msg)

    # ハッシュから例外オブジェクトを抽出・変換し、ハッシュにマージし直して返す
    error = message[:error] || message[:e]

    if error.is_a?(Exception)
      exception_payload = format_exception(error)
      message = message.except(:error, :e).merge(exception_payload)
    end

    # ハッシュから Request / Response オブジェクトを抽出し、
    # LogEntry HttpRequest 形式に変換したものをハッシュにマージし直して返す
    if message[:request].is_a?(ActionDispatch::Request) && message[:response].is_a?(ActionDispatch::Response)
      request = message.delete(:request)
      response = message.delete(:response)
      duration_ms = message[:duration]

      message[:httpRequest] = format_http_request(request, response, duration_ms)
    end

    message
  end

  # 例外オブジェクトを構造化ログに展開して返す
  def format_exception(exception)
    return {} unless exception.is_a?(Exception)

    {
      message: exception.message,
      stack_trace: exception.backtrace&.join("\n")
    }
  end

  def format_http_request(request, response, duration_ms)
    latency_sec = duration_ms / 1000.0

    {
      requestMethod: request.method,
      requestUrl: request.original_url,
      status: response.status,
      userAgent: request.user_agent,
      remoteIp: request.env['REMOTE_ADDR'],
      serverIp: request.env['SERVER_ADDR'],
      referer: request.referer,
      protocol: request.env['HTTP_VERSION'],
      latency: "#{latency_sec.round(9)}s"
    }.compact
  end

  def build_request_context(source_location = nil)
    result = {}

    if source_location
      result['logging.googleapis.com/sourceLocation'] = {
        file: source_location.path,
        line: source_location.lineno,
        function: source_location.base_label
      }
    end

    trace_context = RequestContext.trace_context

    if trace_context && ENV['GOOGLE_PROJECT_ID']
      trace_id, span_id = trace_context.split(';').first.split('/')
      result['logging.googleapis.com/trace'] = "projects/#{ENV['GOOGLE_PROJECT_ID']}/traces/#{trace_id}"
      result['logging.googleapis.com/spanId'] = span_id
      result['logging.googleapis.com/trace_sampled'] = true
    end

    request_id = RequestContext.request_id
    user_id = RequestContext.user&.id
    locale = RequestContext.locale

    result[:request_id] = request_id if request_id
    result[:user_id] = user_id if user_id
    result[:locale] = locale if locale

    result
  end
end
