source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.1.7'

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

gem 'bootsnap', require: false
gem 'google-cloud-pubsub'
gem 'google-cloud-storage'
gem 'google_iid_client', git: 'https://github.com/yusuke-suzuki/google_iid_client.git', branch: 'master', ref: '79a6050'
gem 'google_places'
gem 'http_accept_language'
gem 'jbuilder'
gem 'jwt'
gem 'mysql2', '~> 0.5.3'
gem 'puma'
gem 'rack-cors'

group :development, :test do
  gem 'bullet'
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'dotenv-rails'
  gem 'rubocop', '~> 1.56', require: false
end

group :development do
  gem 'listen', '>= 3.0.5', '< 3.3'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'pry-doc'
  gem 'pry-rails'
  gem 'ruby-lsp-rails'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end
