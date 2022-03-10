# Memoet

[![Memoet CI](https://github.com/memoetapp/memoet/actions/workflows/memoet.yml/badge.svg)](https://github.com/memoetapp/memoet/actions/workflows/memoet.yml)


> Play quizzes & review flashcards to memorize everything using spaced repetition method

## User guide

See [memoet.gitbook.io](https://memoet.gitbook.io/docs).

## Developer guide

1. Install `asdf`

Follow instructions [here](https://asdf-vm.com/).

2. Install `Rust`

Follow instructions [here](https://www.rust-lang.org/tools/install).

3. Install `erlang`, `elixir` and `nodejs`

```sh
asdf install
```

4. Install project dependencies

```sh
mix deps.get
(cd assets && npm i)
```

5. Migrate database & start server

```sh
mix ecto.setup
mix phx.server
```

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Deployment

- Docker: [docker-compose.yml](./docker-compose.yml).

- Ubuntu: [ubuntu.sh](scripts/ubuntu.sh)

- Heroku: [heroku.sh](scripts/heroku.sh)

### Environment

- Basic setup:

| Environment          | Required? | Hints |
|----------------------|-----------|-------|
| `SECRET_KEY_BASE`    | Yes       |Used for Cookie, should be at least 30 chars long|
| `DATABASE_URL`       | Yes       | |
| `DATABASE_SSL`       | No        | |
| `DATABASE_CERT`      | No        | |

- For your custom domain:

| Environment             | Example       |
| ----------------------- | ------------- |
| `URL_HOST`              | memoet.com    |
| `URL_PORT`              | 443           |
| `URL_SCHEMA`            | https         |

- For uploading images to S3:

| Environment             | Example                |
| ----------------------- | ---------------------- |
| `AWS_BUCKET_NAME`       | cdn.memoet.com         |
| `AWS_ACCESS_KEY_ID`     | xxxxxxxxxxxxxxxx       |
| `AWS_SECRET_ACCESS_KEY` | xxxxxxxxxxxxxxxx       |
| `AWS_REGION`            | us-east-1              |
| `AWS_ASSET_HOST`        | https://cdn.memoet.com |

- Extra configuration:

| Environment          | Info                  |
|----------------------|-----------------------|
| `SENDINBLUE_API_KEY` | For password recovery |
| `SENTRY_DSN`         | For error logging     |

## Hosted version

[memoet.manhtai.com](https://memoet.manhtai.com)
