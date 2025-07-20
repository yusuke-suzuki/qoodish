source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 7.2.2.1'

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

gem 'bootsnap', require: false
gem 'google-cloud-storage'
gem 'jbuilder'
gem 'jwt'
gem 'mysql2', '~> 0.5.3'
gem 'opentelemetry-exporter-otlp'
gem 'opentelemetry-instrumentation-all'
gem 'opentelemetry-sdk'
gem 'puma'
gem 'rack-cors'

group :development, :test do
  gem 'bullet'
  gem 'dotenv-rails'
  gem 'rubocop', '~> 1.56', require: false
end

group :development do
  gem 'ruby-lsp-rails'
end
