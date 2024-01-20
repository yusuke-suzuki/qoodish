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
gem 'google-cloud-storage'
gem 'jbuilder'
gem 'jwt'
gem 'mysql2', '~> 0.5.3'
gem 'puma'
gem 'rack-cors'

group :development, :test do
  gem 'bullet'
  gem 'dotenv-rails'
  gem 'rubocop', '~> 1.56', require: false
end

group :development do
  gem 'listen', '>= 3.0.5', '< 3.3'
  gem 'ruby-lsp-rails'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end
