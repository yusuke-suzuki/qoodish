source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.0.0'

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

gem 'bootsnap', require: false
gem 'dotenv-rails'
gem 'fcm_client', git: 'https://github.com/yusuke-suzuki/fcm_client.git', branch: 'master', ref: '57e92b6'
gem 'google_iid_client', git: 'https://github.com/yusuke-suzuki/google_iid_client.git', branch: 'master', ref: '79a6050'
gem 'grpc', '1.24.0', platforms: ['ruby']
gem 'google-gax', '1.8.1', platforms: ['ruby']
gem 'google-protobuf', '3.9.2', platforms: ['ruby']
gem 'google-cloud-pubsub', '1.1.2', platforms: ['ruby']
gem 'google_places'
gem 'googleauth'
gem 'http_accept_language'
gem 'jbuilder'
gem 'jwt'
gem 'mysql2', '~> 0.5.2'
gem 'puma'
gem 'rack-cors'
gem 'redis-objects'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
end

group :development do
  gem 'listen', '>= 3.0.5', '< 3.3'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'pry-rails'
  gem 'pry-doc'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
