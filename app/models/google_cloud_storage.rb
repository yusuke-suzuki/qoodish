# frozen_string_literal: true

class GoogleCloudStorage
  ENDPOINT = 'https://storage.googleapis.com'
  SCOPES = 'https://www.googleapis.com/auth/devstorage.read_write'
  LOCATION = %r{\Ags://(?<bucket>[^/]+)/?(?<prefix>.*)\z}.freeze

  class UploadError < StandardError; end

  attr_reader :bucket, :prefix

  def initialize(location)
    match = LOCATION.match(location)
    raise ArgumentError, "#{location} is not a gs://BUCKET/PREFIX location" unless match

    @bucket = match[:bucket]
    @prefix = match[:prefix].delete_suffix('/')
  end

  def object_name(name)
    [prefix.presence, name].compact.join('/')
  end

  def put(name, body, content_type: 'application/octet-stream')
    response = faraday.post("/upload/storage/v1/b/#{ERB::Util.url_encode(bucket)}/o") do |req|
      req.params['uploadType'] = 'media'
      req.params['name'] = object_name(name)
      req.headers['Authorization'] = "Bearer #{google_auth.fetch_access_token(SCOPES)}"
      req.headers['Content-Type'] = content_type
      req.body = body
    end

    return if response.success?

    raise UploadError, "Uploading #{object_name(name)} to #{bucket} failed with status #{response.status}"
  end

  private

  def faraday
    @faraday ||= Faraday.new(ENDPOINT) do |f|
      f.options.timeout = 300
      f.options.open_timeout = 10
    end
  end

  def google_auth
    @google_auth ||= GoogleAuth.new
  end
end
