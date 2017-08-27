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
`cp .env.sample .env`  
`vim .env`  
`cp docker-compose.dev.yml docker-compose.yml`  
`vim docker-compose.yml`  
`docker-compose build`  
`docker-compose up -d`  
`docker-compose run api bundle exec rails db:setup`  
`docker-compose logs -f api`  
