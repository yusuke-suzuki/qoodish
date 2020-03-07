# Qoodish API

Qoodish API.

## Set up development environment

1. Install [docker-compose](https://docs.docker.com/compose/install/)
2. Install [gcloud](https://cloud.google.com/sdk/docs?hl=ja)

## Start app

```sh
docker-compose up -d
docker-compose run api bundle exec rails db:setup
```

## Test

```sh
docker-compose run api bundle exec rails test
```
