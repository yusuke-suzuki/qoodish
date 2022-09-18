# Qoodish API

Qoodish API.

## Set up development environment

1. Install [docker-compose](https://docs.docker.com/compose/install/)
2. Install [gcloud](https://cloud.google.com/sdk/docs?hl=ja)
3. Get secrets from Secret Manager

```
gcloud beta secrets versions access latest --secret=DOTENV_API > .env
```

## Start app

```sh
docker-compose up -d
docker-compose run --rm api bundle exec rails db:setup
```

## Test

```sh
docker-compose run api bundle exec rails test
```
