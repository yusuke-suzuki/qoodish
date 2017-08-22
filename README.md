# Qoodish API
Qoodish API.

## Set Up
`bundle`  
`cp .env.sample .env`  
`vim .env`  
`bin/rails db:setup`

## Start app
`bin/rails s`

## Test
`bin/rails test`

## Development environment using Docker
`docker-compose build`  
`docker-compose up -d`  
`docker-compose run api bundle exec rails db:setup`  
`docker-compose logs -f api`  
