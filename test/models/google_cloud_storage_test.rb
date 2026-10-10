require 'test_helper'

class GoogleCloudStorageTest < ActiveSupport::TestCase
  test 'reads the bucket and prefix of a gs:// location' do
    storage = GoogleCloudStorage.new('gs://exports/d1/2026-10-10/')

    assert_equal 'exports', storage.bucket
    assert_equal 'd1/2026-10-10/part-00001.sql', storage.object_name('part-00001.sql')
    assert_equal 'manifest.json', GoogleCloudStorage.new('gs://exports').object_name('manifest.json')
  end

  test 'refuses a location that is not in Cloud Storage' do
    assert_raises(ArgumentError) { GoogleCloudStorage.new('/tmp/exports') }
  end

  test 'uploads an object with the service account token' do
    captured = {}
    stubs = Faraday::Adapter::Test::Stubs.new
    stubs.post('/upload/storage/v1/b/exports/o') do |env|
      captured = { params: env.params, headers: env.request_headers.to_h, body: env.body }
      [200, { 'Content-Type' => 'application/json' }, '{}']
    end

    stub_google_auth(users(:me)) do
      storage_with(stubs, 'gs://exports/d1').put('part-00001.sql', 'SELECT 1;', content_type: 'application/sql')
    end

    assert_equal({ 'uploadType' => 'media', 'name' => 'd1/part-00001.sql' }, captured[:params])
    assert_equal 'Bearer dummy_access_token', captured[:headers]['Authorization']
    assert_equal 'application/sql', captured[:headers]['Content-Type']
    assert_equal 'SELECT 1;', captured[:body]
  end

  test 'raises when Cloud Storage refuses the upload' do
    stubs = Faraday::Adapter::Test::Stubs.new
    stubs.post('/upload/storage/v1/b/exports/o') { [403, {}, '{}'] }

    stub_google_auth(users(:me)) do
      assert_raises(GoogleCloudStorage::UploadError) do
        storage_with(stubs, 'gs://exports').put('part-00001.sql', 'SELECT 1;')
      end
    end
  end

  private

  def storage_with(stubs, location)
    GoogleCloudStorage.new(location).tap do |storage|
      storage.instance_variable_set(:@faraday, Faraday.new { |f| f.adapter :test, stubs })
    end
  end
end
