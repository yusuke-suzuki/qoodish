class GoogleAuth
  CLIENT_CERT_URL = 'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com'.freeze

  def initialize
    @project_id = ENV['GOOGLE_PROJECT_ID']
    @aud = ENV['GOOGLE_PROJECT_ID']
    @iss = "https://securetoken.google.com/#{ENV['GOOGLE_PROJECT_ID']}"
  end

  def verify_jwt(jwt)
    key_source = Google::Auth::IDTokens::X509CertHttpKeySource.new(CLIENT_CERT_URL, algorithm: 'RS256')
    verifier = Google::Auth::IDTokens::Verifier.new
    verifier.verify(jwt, key_source: key_source, aud: @aud, iss: @iss)
  rescue => e
    Rails.logger.fatal("Failed to verify ID Token: #{e}")
    raise Exceptions::FirebaseAuthError
  end
end
