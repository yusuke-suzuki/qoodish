require 'test_helper'

class CloudflareAccessTest < ActiveSupport::TestCase
  TEAM_DOMAIN = 'qoodish.cloudflareaccess.com'.freeze
  AUDIENCE = 'admin-aud'.freeze

  setup do
    @key = OpenSSL::PKey::RSA.generate(2048)
    @jwk = JWT::JWK.new(@key, kid: 'key-1')
    @access = CloudflareAccess.new(team_domain: TEAM_DOMAIN, audience: AUDIENCE)
  end

  def certs
    { 'keys' => [@jwk.export] }
  end

  def token(overrides = {}, key: @key, kid: @jwk.kid)
    payload = {
      'iss' => "https://#{TEAM_DOMAIN}",
      'aud' => [AUDIENCE],
      'email' => 'moderator@example.com',
      'exp' => 5.minutes.from_now.to_i
    }.merge(overrides)

    JWT.encode(payload, key, 'RS256', { kid: kid })
  end

  def verify(jwt)
    @access.stub(:fetch_certs, certs) { @access.verify(jwt) }
  end

  test 'a token Access signed for the application yields its claims' do
    assert_equal 'moderator@example.com', verify(token)['email']
  end

  test 'a token signed by another key is rejected' do
    assert_nil verify(token({}, key: OpenSSL::PKey::RSA.generate(2048)))
  end

  test 'a token issued for another application is rejected' do
    assert_nil verify(token({ 'aud' => ['other-aud'] }))
  end

  test 'a token issued by another team is rejected' do
    assert_nil verify(token({ 'iss' => 'https://other.cloudflareaccess.com' }))
  end

  test 'an expired token is rejected' do
    assert_nil verify(token({ 'exp' => 1.minute.ago.to_i }))
  end

  test 'a token with an unknown key id is rejected' do
    assert_nil verify(token({}, kid: 'unknown'))
  end

  test 'a malformed token is rejected' do
    assert_nil verify('not-a-jwt')
  end

  test 'an unknown key id refetches the certs at most once per interval' do
    fetches = 0
    fetch = lambda do
      fetches += 1
      certs
    end

    Rails.stub(:cache, ActiveSupport::Cache::MemoryStore.new) do
      @access.stub(:fetch_certs, fetch) do
        @access.verify(token)
        3.times { @access.verify(token({}, kid: 'unknown')) }

        assert_equal 1, fetches

        travel CloudflareAccess::CERTS_MIN_REFRESH_INTERVAL + 1.second
        @access.verify(token({}, kid: 'unknown'))

        assert_equal 2, fetches
      end
    end
  end

  test 'a failure to fetch the certs rejects the token' do
    failing_fetch = -> { raise Faraday::ConnectionFailed, 'timed out' }

    @access.stub(:fetch_certs, failing_fetch) do
      assert_nil @access.verify(token)
    end
  end

  test 'the certs are fetched over https from the team domain' do
    requested_url = nil
    body = JSON.generate(certs)
    connection = Object.new
    connection.define_singleton_method(:get) do |url|
      requested_url = url
      Struct.new(:success?, :body).new(true, body)
    end

    Rails.stub(:cache, ActiveSupport::Cache::MemoryStore.new) do
      Faraday.stub(:new, connection) do
        assert_equal 'moderator@example.com', @access.verify(token)['email']
      end
    end

    assert_equal "https://#{TEAM_DOMAIN}/cdn-cgi/access/certs", requested_url
  end

  test 'nothing is accepted until the team domain and audience are configured' do
    unconfigured = CloudflareAccess.new(team_domain: nil, audience: nil)

    assert_nil unconfigured.verify(token)
  end
end
