require 'jwt'

module Firebase
  class Auth
    ALGORITHM = 'RS256'.freeze
    ISSUER_BASE_URL = 'https://securetoken.google.com/'.freeze
    CLIENT_CERT_URL = 'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com'.freeze

    def verify_id_token(token)
      Rails.logger.info('Try to verify firebase id token...')
      Rails.logger.info("Token: #{token}")
      raise Exceptions::FirebaseAuthError, 'id token must be a String' unless token.is_a?(String)

      full_decoded_token = decode_token(token)

      err_msg = validate_jwt(full_decoded_token)
      raise Exceptions::FirebaseAuthError, err_msg if err_msg

      public_key = fetch_public_keys[full_decoded_token[:header]['kid']]
      unless public_key
        raise Exceptions::FirebaseAuthError, 'Firebase ID token has "kid" claim which does not correspond to a known public key. Most likely the ID token is expired, so get a fresh token from your client app and try again.'
      end

      certificate = OpenSSL::X509::Certificate.new(public_key)
      decoded_token = decode_token(token, certificate.public_key, true, algorithm: ALGORITHM, verify_iat: false)
      Rails.logger.info('Successfully verified firebase id token.')

      {
        uid: decoded_token[:payload]['sub'],
        decoded_token: decoded_token
      }
    end

    private

    def decode_token(token, key = nil, verify = false, options = {})
      begin
        decoded_token = JWT.decode(token, key, verify, options)
      rescue JWT::ExpiredSignature => e
        Rails.logger.error(e)
        raise Exceptions::FirebaseAuthError, 'Firebase ID token has expired. Get a fresh token from your client app and try again.'
      rescue StandardError => e
        Rails.logger.error(e)
        raise Exceptions::FirebaseAuthError, 'Firebase ID token has invalid signature.'
      end

      {
        payload: decoded_token[0],
        header: decoded_token[1]
      }
    end

    def fetch_public_keys
      uri = URI.parse(CLIENT_CERT_URL)
      https = Net::HTTP.new(uri.host, uri.port)
      https.use_ssl = true

      res = https.start do
        https.get(uri.request_uri)
      end
      data = JSON.parse(res.body)

      if data['error']
        msg = "Error fetching public keys for Google certs: #{data['error']}"
        msg += " (#{res['error_description']})" if data['error_description']

        raise Exceptions::FirebaseAuthError, msg
      end

      data
    end

    def validate_jwt(json)
      project_id = ENV['GCP_PROJECT_ID']
      payload = json[:payload]
      header = json[:header]

      return 'Firebase ID token has no "kid" claim.' unless header['kid']
      return "Firebase ID token has incorrect algorithm. Expected \"#{ALGORITHM}\" but got \"#{header['alg']}\"." unless header['alg'] == ALGORITHM
      return "Firebase ID token has incorrect \"aud\" (audience) claim. Expected \"#{project_id}\" but got \"#{payload['aud']}\"." unless payload['aud'] == project_id

      issuer = ISSUER_BASE_URL + project_id
      return "Firebase ID token has incorrect \"iss\" (issuer) claim. Expected \"#{issuer}\" but got \"#{payload['iss']}\"." unless payload['iss'] == issuer

      return 'Firebase ID token has no "sub" (subject) claim.' unless payload['sub'].is_a?(String)
      return 'Firebase ID token has an empty string "sub" (subject) claim.' if payload['sub'].empty?
      return 'Firebase ID token has "sub" (subject) claim longer than 128 characters.' if payload['sub'].size > 128

      nil
    end
  end
end
