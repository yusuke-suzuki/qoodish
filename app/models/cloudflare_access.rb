class CloudflareAccess
  CERTS_CACHE_KEY = 'cloudflare_access/certs'.freeze
  CERTS_TTL = 1.hour
  CERTS_MIN_REFRESH_INTERVAL = 5.minutes
  CERTS_OPEN_TIMEOUT = 2
  CERTS_TIMEOUT = 5

  def initialize(team_domain: ENV['CF_ACCESS_TEAM_DOMAIN'], audience: ENV['CF_ACCESS_AUD'])
    @issuer = "https://#{team_domain}" if team_domain.present?
    @audience = audience
  end

  def verify(token)
    return if @issuer.blank? || @audience.blank? || token.blank?

    payload, = JWT.decode(
      token, nil, true,
      algorithms: ['RS256'],
      jwks: method(:load_certs),
      iss: @issuer, verify_iss: true,
      aud: @audience, verify_aud: true
    )
    payload
  rescue JWT::DecodeError, Faraday::Error, JSON::ParserError => e
    Rails.logger.warn("Cloudflare Access JWT rejected: #{e.class} - #{e.message}")
    nil
  end

  private

  def load_certs(options)
    cached = Rails.cache.read(CERTS_CACHE_KEY)
    return cached[:certs] if cached && !refresh_due?(cached, options)

    fresh = { certs: fetch_certs, fetched_at: Time.current }
    Rails.cache.write(CERTS_CACHE_KEY, fresh, expires_in: CERTS_TTL)
    fresh[:certs]
  end

  def refresh_due?(cached, options)
    options[:kid_not_found] && cached[:fetched_at] < CERTS_MIN_REFRESH_INTERVAL.ago
  end

  def fetch_certs
    connection = Faraday.new(request: { open_timeout: CERTS_OPEN_TIMEOUT, timeout: CERTS_TIMEOUT })
    response = connection.get("#{@issuer}/cdn-cgi/access/certs")
    raise Faraday::Error, "Access certs request failed with status #{response.status}" unless response.success?

    JSON.parse(response.body).slice('keys')
  end
end
