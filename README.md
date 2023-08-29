# Memoet

[![Memoet CI](https://github.com/memoetapp/memoet/actions/workflows/memoet.yml/badge.svg)](https://github.com/memoetapp/memoet/actions/workflows/memoet.yml)


> Play quizzes & review flashcards to memorize everything using spaced repetition method

## User guide

See [memoet.gitbook.io](https://memoet.gitbook.io/docs).

## Developer guide

### Standard way of setting up your development environment

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
mix setup
mix deps.get
(cd assets && npm i)
```

5. Migrate database & start server

```sh
mix ecto.setup
mix phx.server
```

### Nix-shell way of setting up your development environment

This way of setup works only wwhen you have Nix configured for your OS, or are using NixOS

```sh
NIX_ENFORCE_PURITY=0 nix-shell
```

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Deployment

- Docker: [docker-compose.yml](./docker-compose.yml).

- Ubuntu: [ubuntu.sh](scripts/ubuntu.sh)

- Heroku: [heroku.sh](scripts/heroku.sh)

### Environment

- Basic setup:

| Environment          | Required? | Why?                                                                |
|----------------------|-----------|---------------------------------------------------------------------|
| `SECRET_KEY_BASE`    | Yes       | For cookies encryption, can be generate with `openssl rand -hex 48` |
| `DATABASE_URL`       | Yes       | For saving stuffs, only Postgres is supported for now               |
| `DATABASE_SSL`       | No        |                                                                     |
| `DATABASE_CERT`      | No        |                                                                     |
| `DATABASE_IPV6`      | No        | For database conn with IP v6                                        |

- For your custom domain:

| Environment             | Example       |
| ----------------------- | ------------- |
| `URL_HOST`              | memoet.com    |
| `URL_PORT`              | 443           |
| `URL_SCHEMA`            | https         |

- For uploading images to S3:

| Environment             | Example                |
|-------------------------|------------------------|
| `AWS_BUCKET_NAME`       | cdn.memoet.com         |
| `AWS_ACCESS_KEY_ID`     | xxxxxxxxxxxxxxxx       |
| `AWS_SECRET_ACCESS_KEY` | xxxxxxxxxxxxxxxx       |
| `AWS_REGION`            | us-east-1              |
| `AWS_ASSET_HOST`        | https://cdn.memoet.com |

- Extra configuration:

| Environment          | Why?                        |
|----------------------|-----------------------------|
| `SENDINBLUE_API_KEY` | For password recovery email |
| `SENTRY_DSN`         | For error logging           |
