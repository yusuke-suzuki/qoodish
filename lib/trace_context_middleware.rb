# frozen_string_literal: true

# Google Cloud Trace Context をリクエスト間で管理するミドルウェア
# X-Cloud-Trace-Context ヘッダーから trace context を抽出し、ログ出力時に利用可能にする
class TraceContextMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    extract_and_set_trace_context(env)
    @app.call(env)
  ensure
    clear_trace_context
  end

  private

  def extract_and_set_trace_context(env)
    trace_header = env['HTTP_X_CLOUD_TRACE_CONTEXT']

    return unless trace_header

    Thread.current[:trace_context] = trace_header
  end

  def clear_trace_context
    Thread.current[:trace_context] = nil
  end
end
