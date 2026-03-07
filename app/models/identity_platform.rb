class IdentityPlatform
  ENDPOINT = 'https://identitytoolkit.googleapis.com'.freeze
  SCOPES = 'https://www.googleapis.com/auth/cloud-platform'.freeze
  USER_NOT_FOUND = 'USER_NOT_FOUND'.freeze

  def delete_account(uid)
    access_token = google_auth.fetch_access_token(SCOPES)
    response = faraday.post(
      '/v1/accounts:delete',
      { localId: uid, targetProjectId: ENV['GOOGLE_PROJECT_ID'] },
      'Authorization' => "Bearer #{access_token}"
    )

    return if response.success?

    error_message = response.body&.dig('error', 'message')
    if error_message == USER_NOT_FOUND
      Rails.logger.warn("Identity Platform account not found for uid: #{uid}")
      return
    end

    Rails.logger.error("Identity Platform error: #{error_message}")
    raise Exceptions::InternalServerError
  rescue Faraday::Error => e
    Rails.logger.error(e)
    raise Exceptions::InternalServerError
  end

  private

  def faraday
    @faraday ||= Faraday.new(ENDPOINT) do |f|
      f.request :json
      f.response :json
    end
  end

  def google_auth
    @google_auth ||= GoogleAuth.new
  end
end
