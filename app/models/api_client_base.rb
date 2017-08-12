class ApiClientBase
  def initialize(options = {})
    @options = options
    @logger = @options[:logger] if @options[:logger].present?
  end

  def request(path, headers, params, method = :get)
    conn = Faraday.new(url: endpoint, ssl: { verify: false }) do |faraday|
      faraday.request :url_encoded
      faraday.adapter Faraday.default_adapter
    end

    logger.info('API Request START ----------')
    logger.info("Class: #{self.class.name}")
    logger.info("Endpoint: #{endpoint}")
    logger.info("Method: #{method}, Path: #{path}")

    response = conn.send(method, path) do |req|
      if params.present?
        if method == :get
          req.params = params
        else
          req.body = params
        end
      end

      req.headers.merge!(headers)
      req.options[:timeout] = timeout

      logger.info("Request header: #{req.headers}")
      logger.info("Request params: #{params}")
    end

    logger.info("Response status: #{response.status}")
    logger.info("Response body: #{response.body}")
    logger.info('API Request END ----------')

    response
  rescue => ex
    Rails.logger.error('HTTP request failed.')
    raise ex
  end

  def endpoint
    @options[:endpoint]
  end

  def retry_count
    @options[:retry_count] || 0
  end

  def retry_sleep_second
    @options[:retry_sleep_second] || 0
  end

  def timeout
    @options[:timeout] || 60
  end

  def logger
    @options[:logger] || Rails.logger
  end
end
