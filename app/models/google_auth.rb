class GoogleAuth
  CLIENT_CERT_URL = 'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com'.freeze
  FCM_SCOPE = 'https://www.googleapis.com/auth/firebase.messaging'.freeze

  def initialize
    @project_id = ENV['GOOGLE_PROJECT_ID']
  end

  def verify_jwt(jwt, aud = ENV['GOOGLE_PROJECT_ID'], iss = "https://securetoken.google.com/#{ENV['GOOGLE_PROJECT_ID']}")
    key_source = Google::Auth::IDTokens::X509CertHttpKeySource.new(CLIENT_CERT_URL, algorithm: 'RS256')
    verifier = Google::Auth::IDTokens::Verifier.new
    verifier.verify(jwt, key_source: key_source, aud: aud, iss: iss)
  rescue StandardError => e
    Rails.logger.fatal("Failed to verify ID Token: #{e}")
    raise Exceptions::FirebaseAuthError
  end

  def verify_oidc(jwt, aud)
    Google::Auth::IDTokens.verify_oidc(jwt, aud: aud)
  rescue StandardError => e
    Rails.logger.fatal("Failed to verify ID Token: #{e}")
    raise Exceptions::OidcAuthError
  end

  def fetch_access_token(scope)
    authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
      scope: scope
    )
    token = authorizer.fetch_access_token!
    token['access_token']
  end
end
