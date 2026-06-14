module Cloudflare
  class Images
    ENDPOINT = 'https://api.cloudflare.com'.freeze
    DELIVERY_HOST = 'imagedelivery.net'.freeze
    SERVICE_IDENTIFIER = 'qoodish'.freeze

    # Named variants pre-configured in the Cloudflare Images dashboard.
    # Order matches the qoodish-web `ImageVariants` type. The pixel sizes
    # come from the dashboard (avatar 80x80, card 400x400, hero 800x800,
    # ogp 1200x630); the backend just references the variant names.
    NAMED_VARIANTS = %i[avatar card hero ogp].freeze

    def create_direct_upload
      response = multipart_faraday.post(direct_upload_path) do |req|
        req.headers['Authorization'] = "Bearer #{api_token}"
        req.headers['Content-Type'] = 'multipart/form-data'
        req.body = { id: build_custom_id, metadata: metadata_json }
      end

      raise_unless_success!(response)

      result = response.body['result']
      { id: result['id'], upload_url: result['uploadURL'] }
    end

    def upload_from_url(source_url)
      response = multipart_faraday.post(images_path) do |req|
        req.headers['Authorization'] = "Bearer #{api_token}"
        req.headers['Content-Type'] = 'multipart/form-data'
        req.body = { url: source_url, id: build_custom_id, metadata: metadata_json }
        # Cloudflare fetches the source URL server-side; the default 10s is
        # too tight when the origin (e.g. GCS) responds slowly.
        req.options.timeout = 60
      end

      raise_unless_success!(response)

      image_id = response.body.dig('result', 'id')
      return nil if image_id.blank?

      Cloudflare::Images.delivery_url(image_id)
    end

    def delete(image_id)
      response = faraday.delete("#{images_path}/#{image_id}") do |req|
        req.headers['Authorization'] = "Bearer #{api_token}"
      end

      return if response.success?

      if response.status == 404
        Rails.logger.warn("Cloudflare image #{image_id} not found")
        return
      end

      Rails.logger.error("Cloudflare Images error: #{response.body}")
      raise Exceptions::InternalServerError
    end

    def self.delivery_url(image_id, variant: 'public')
      "https://#{DELIVERY_HOST}/#{ENV.fetch('CLOUDFLARE_IMAGES_ACCOUNT_HASH')}/#{image_id}/#{variant}"
    end

    # Replace the variant segment of a delivery URL with the given variant
    # name. The variant must be configured in the Cloudflare Images dashboard.
    def self.variant_url(url, variant)
      url.sub(%r{/[^/]+\z}, "/#{variant}")
    end

    def self.extract_id(url)
      return nil if url.blank?

      uri = URI.parse(url)
      return nil unless uri.host == DELIVERY_HOST

      # path layout: /<account-hash>/<image-id...>/<variant>
      # image-id may contain slashes when a custom ID is used.
      parts = uri.path.split('/').reject(&:empty?)
      return nil if parts.size < 3

      parts[1..-2].join('/')
    rescue URI::InvalidURIError
      nil
    end

    private

    def build_custom_id
      "#{SERVICE_IDENTIFIER}/#{SecureRandom.uuid}"
    end

    def metadata_json
      { app: SERVICE_IDENTIFIER, env: app_env }.to_json
    end

    # APP_ENV distinguishes deployments that all run with RAILS_ENV=production
    # (prod and dev Cloud Run services). Falls back to Rails.env for local runs
    # where APP_ENV is not set.
    def app_env
      ENV.fetch('APP_ENV', Rails.env)
    end

    def raise_unless_success!(response)
      return if response.success? && response.body.is_a?(Hash) && response.body['success']

      Rails.logger.error("Cloudflare Images error: #{response.body}")
      raise Exceptions::InternalServerError
    end

    def account_id
      ENV.fetch('CLOUDFLARE_ACCOUNT_ID')
    end

    def api_token
      ENV.fetch('CLOUDFLARE_IMAGES_API_TOKEN')
    end

    def direct_upload_path
      "/client/v4/accounts/#{account_id}/images/v2/direct_upload"
    end

    def images_path
      "/client/v4/accounts/#{account_id}/images/v1"
    end

    def faraday
      @faraday ||= Faraday.new(ENDPOINT) do |f|
        f.options.timeout = 10
        f.options.open_timeout = 5
        f.response :json
      end
    end

    def multipart_faraday
      @multipart_faraday ||= Faraday.new(ENDPOINT) do |f|
        f.options.timeout = 10
        f.options.open_timeout = 5
        f.request :multipart
        f.response :json
      end
    end
  end
end
