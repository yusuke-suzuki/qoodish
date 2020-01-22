# Qoodish API

Qoodish API.

## Set up development environment

```
# Decrypt secrets
gcloud kms decrypt --ciphertext-file=.env.development.enc --plaintext-file=.env --location=global --keyring=qoodish --key=qoodish
gcloud kms decrypt --ciphertext-file=gcp-credentials.dev.json.enc --plaintext-file=gcp-credentials.json --location=global --keyring=qoodish --key=qoodish
```

## Start app

```
docker-compose build
docker-compose up -d
docker-compose run api bundle exec rails db:setup
```

## Test

```
docker-compose run api bundle exec rails test
```
