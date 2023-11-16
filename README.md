# Qoodish API

## Description

https://qoodish.com

## Installation

```bash
$ bundle install
```

## Decrypt secrets

```bash
$ gcloud secrets versions access latest --secret=QOODISH_API_DOTENV --project=$PROJECT_ID --out-file=.env
```

## Running app

```bash
$ pnpm dev
```
