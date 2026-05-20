require 'test_helper'

class Cloudflare::ImagesTest < ActiveSupport::TestCase
  test 'extract_id returns the image id segment for an opaque delivery URL' do
    url = 'https://imagedelivery.net/mockhash/abc123/public'
    assert_equal 'abc123', Cloudflare::Images.extract_id(url)
  end

  test 'extract_id returns the service-scoped id for the standard custom-id delivery URL' do
    url = 'https://imagedelivery.net/mockhash/qoodish/8a5e2b1c/public'
    assert_equal 'qoodish/8a5e2b1c', Cloudflare::Images.extract_id(url)
  end

  test 'extract_id returns the full id for a legacy delivery URL with an env segment' do
    url = 'https://imagedelivery.net/mockhash/qoodish/development/8a5e2b1c/public'
    assert_equal 'qoodish/development/8a5e2b1c', Cloudflare::Images.extract_id(url)
  end

  test 'extract_id returns nil for non-Cloudflare delivery hosts' do
    url = 'https://storage.googleapis.com/qoodish.appspot.com/images/foo.jpg'
    assert_nil Cloudflare::Images.extract_id(url)
  end

  test 'variant_url replaces only the variant segment with the given variant name' do
    url = 'https://imagedelivery.net/mockhash/qoodish/development/8a5e2b1c/public'
    assert_equal 'https://imagedelivery.net/mockhash/qoodish/development/8a5e2b1c/card',
                 Cloudflare::Images.variant_url(url, 'card')
  end

  test 'variant_url_for_legacy_size maps legacy thumbnail sizes to configured variants' do
    url = 'https://imagedelivery.net/mockhash/qoodish/8a5e2b1c/public'
    assert_equal 'https://imagedelivery.net/mockhash/qoodish/8a5e2b1c/avatar',
                 Cloudflare::Images.variant_url_for_legacy_size(url, '200x200')
    assert_equal 'https://imagedelivery.net/mockhash/qoodish/8a5e2b1c/card',
                 Cloudflare::Images.variant_url_for_legacy_size(url, '400x400')
    assert_equal 'https://imagedelivery.net/mockhash/qoodish/8a5e2b1c/hero',
                 Cloudflare::Images.variant_url_for_legacy_size(url, '800x800')
  end

  test 'variant_url_for_legacy_size falls back to public for unmapped sizes' do
    url = 'https://imagedelivery.net/mockhash/qoodish/8a5e2b1c/public'
    assert_equal 'https://imagedelivery.net/mockhash/qoodish/8a5e2b1c/public',
                 Cloudflare::Images.variant_url_for_legacy_size(url, '9999x9999')
  end

  test 'upload_from_url returns the canonical /public URL regardless of variants order' do
    body = {
      'success' => true,
      'result' => {
        'id' => 'qoodish/test/abc',
        # Dashboard order is not guaranteed; place a non-public variant first
        # to confirm the implementation builds the URL from id, not variants.first.
        'variants' => [
          'https://imagedelivery.net/mockhash/qoodish/test/abc/avatar',
          'https://imagedelivery.net/mockhash/qoodish/test/abc/public'
        ]
      }
    }.to_json

    stubs = Faraday::Adapter::Test::Stubs.new
    stubs.post(%r{/client/v4/accounts/.*/images/v1\z}) do
      [200, { 'Content-Type' => 'application/json' }, body]
    end

    connection = build_multipart_connection(stubs)

    with_env('CLOUDFLARE_IMAGES_ACCOUNT_HASH' => 'mockhash') do
      cf = Cloudflare::Images.new
      cf.instance_variable_set(:@multipart_faraday, connection)

      assert_equal 'https://imagedelivery.net/mockhash/qoodish/test/abc/public',
                   cf.upload_from_url('https://example.com/source.jpg')
    end
  end

  test 'upload_from_url encodes the request as multipart/form-data' do
    body = { 'success' => true, 'result' => { 'id' => 'qoodish/test/abc' } }.to_json

    captured_content_type = nil
    captured_body_class = nil

    stubs = Faraday::Adapter::Test::Stubs.new
    stubs.post(%r{/client/v4/accounts/.*/images/v1\z}) do |env|
      captured_content_type = env.request_headers['Content-Type']
      captured_body_class = env.body.class
      [200, { 'Content-Type' => 'application/json' }, body]
    end

    connection = build_multipart_connection(stubs)

    with_env('CLOUDFLARE_IMAGES_ACCOUNT_HASH' => 'mockhash') do
      cf = Cloudflare::Images.new
      cf.instance_variable_set(:@multipart_faraday, connection)
      cf.upload_from_url('https://example.com/source.jpg')
    end

    assert_match %r{\Amultipart/form-data; boundary=}, captured_content_type
    refute_equal Hash, captured_body_class
  end

  private

  def build_multipart_connection(stubs)
    Faraday.new do |f|
      f.request :multipart
      f.response :json
      f.adapter :test, stubs
    end
  end

  def with_env(overrides)
    prior = overrides.transform_values { |_| nil }
    overrides.each_key { |k| prior[k] = ENV[k] }
    overrides.each { |k, v| ENV[k] = v }
    yield
  ensure
    prior.each { |k, v| ENV[k] = v }
  end
end
