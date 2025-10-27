# frozen_string_literal: true

class RequestContextMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    request = ActionDispatch::Request.new(env)

    RequestContext.locale = calculate_locale(request)
    user = authenticate_user(request)
    RequestContext.user = user
    RequestContext.user_id = user&.id
    RequestContext.request_id = request.request_id

    @app.call(env)
  end

  private

  def calculate_locale(request)
    header = request.env['HTTP_ACCEPT_LANGUAGE']
    extracted_locale = header&.scan(/^[a-z]{2}/)&.first

    locale = if I18n.available_locales.map(&:to_s).include?(extracted_locale)
               extracted_locale
             else
               I18n.default_locale
             end

    I18n.locale = locale
    locale
  end

  def authenticate_user(request)
    token = extract_token(request)
    return unless token

    payload = verify_token(token)
    return unless payload

    RequestContext.jwt_payload = payload

    User.find_by(uid: payload['sub'])
  end

  def extract_token(request)
    request.headers['Authorization']&.split(' ', 2)&.last
  end

  def verify_token(token)
    GoogleAuth.new.verify_jwt(token)
  rescue Google::Auth::IDTokens::VerificationError => e
    # 認証エラーはここではログ出力するに留め、後続の処理 (コントローラー) での認証チェックに委ねる
    Rails.logger.warn("JWT verification failed in middleware: #{e.class} - #{e.message}")
    nil
  end
end
