# frozen_string_literal: true

# Google Cloud Trace Context をリクエスト間で管理するミドルウェア
# X-Cloud-Trace-Context ヘッダーから trace context を抽出し、ログ出力時に利用可能にする
class TraceContextMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    trace_header = env['HTTP_X_CLOUD_TRACE_CONTEXT']
    RequestContext.trace_context = trace_header if trace_header
    @app.call(env)
  end
end
