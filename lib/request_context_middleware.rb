# frozen_string_literal: true

class RequestContextMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    clear_context
    request = ActionDispatch::Request.new(env)

    # コンテキスト情報を計算し、Thread.current に設定
    locale = calculate_locale(request)
    user = authenticate_and_get_user(request)

    Thread.current[:request_id] = request.request_id
    Thread.current[:locale] = locale
    Thread.current[:user_id] = user&.id

    @app.call(env)
  ensure
    # リクエスト終了後にコンテキストをクリア
    clear_context
  end

  private

  # ロケールを計算し、I18n.locale を設定して、計算結果を返す
  def calculate_locale(request)
    header = request.env['HTTP_ACCEPT_LANGUAGE']
    locale = header&.scan(/^[a-z]{2}/)&.first || I18n.default_locale
    I18n.locale = locale
    locale
  end

  # ユーザー認証を試み、request.env を設定して、ユーザーオブジェクトを返す
  def authenticate_and_get_user(request)
    token = extract_token(request)
    return unless token

    payload = verify_token(token)
    return unless payload

    request.env['qoodish.jwt_payload'] = payload

    user = User.find_by(uid: payload['sub'])
    return unless user

    request.env['qoodish.current_user'] = user
    user
  end

  def extract_token(request)
    request.headers['Authorization']&.split(' ', 2)&.last
  end

  def verify_token(token)
    GoogleAuth.new.verify_jwt(token)
  rescue StandardError => e
    # 認証エラーはここではログ出力するに留め、後続の処理 (コントローラー) での認証チェックに委ねる
    Rails.logger.info("JWT verification failed in middleware: #{e.class} - #{e.message}")
    nil
  end

  def clear_context
    Thread.current[:request_id] = nil
    Thread.current[:user_id] = nil
    Thread.current[:locale] = nil
  end
end
