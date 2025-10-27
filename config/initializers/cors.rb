# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.

# Read more: https://github.com/cyu/rack-cors

# Rails.application.config.middleware.insert_before 0, Rack::Cors do
#   allow do
#     origins "example.com"
#
#     resource "*",
#       headers: :any,
#       methods: [:get, :post, :put, :patch, :delete, :options, :head]
#   end
# end

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    allowed_origins = (ENV['ALLOWED_ENDPOINTS'] || '')
                      .split("\n")
                      .map(&:strip)
                      .reject(&:empty?)
                      .map do |origin|
      # Support regex literals in /pattern/ format
      if origin.start_with?('/') && origin.end_with?('/')
        Regexp.new(origin[1..-2])
      else
        origin
      end
    end

    origins allowed_origins

    resource '*',
             headers: :any,
             methods: %i[get post put patch delete options head]
  end
end
