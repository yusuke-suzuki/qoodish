# Qoodish API

Qoodish API.

## Set credentials for development (Admin)

```
gcloud config set project <GCP project ID>

# Create keyring & key
gcloud kms keyrings create qoodish --location=global
gcloud kms keys create qoodish --location=global --keyring=qoodish --purpose=encryption

# Encrypt secrets
gcloud kms encrypt --plaintext-file=.env.development --ciphertext-file=.env.development.enc --location=global --keyring=qoodish --key=qoodish
gcloud kms encrypt --plaintext-file=firebase-credentials.json --ciphertext-file=firebase-credentials.dev.json.enc --location=global --keyring=qoodish --key=qoodish
```

## Set up development environment

```
gcloud config set project <GCP project ID>

# Decrypt secrets
gcloud kms decrypt --ciphertext-file=.env.development.enc --plaintext-file=.env --location=global --keyring=qoodish --key=qoodish
gcloud kms decrypt --ciphertext-file=firebase-credentials.dev.json.enc --plaintext-file=firebase-credentials.json --location=global --keyring=qoodish --key=qoodish
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
