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

- Ubuntu: [ubuntu.sh](scripts/ubuntu.sh)

- Heroku: [heroku.sh](scripts/heroku.sh)


## Hosted version

[memoet.manhtai.com](https://memoet.manhtai.com)
