# Memoet

[![Memoet CI](https://github.com/memoetapp/memoet/actions/workflows/memoet.yml/badge.svg)](https://github.com/memoetapp/memoet/actions/workflows/memoet.yml)


> Play quizzes & review flashcards to memorize everything using spaced repetition method 


## Documentation

See [memoet.gitbook.io](https://memoet.gitbook.io/docs).


## Local setup

1. Install `asdf`

Instruction [here](https://asdf-vm.com/)

2. Install `erlang`, `elixir` and `nodejs`

```sh
asdf install
```

3. Start your Phoenix server

- Install dependencies with `mix deps.get`
- Create and migrate your database with `mix ecto.setup`
- Install Node.js dependencies with `npm i` inside the `assets` directory
- Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.


## Deployment

- Ubuntu: [ubuntu.sh](scripts/ubuntu.sh)

- Heroku: [heroku.sh](scripts/heroku.sh)


## Hosted version


[memoet.manhtai.com](https://memoet.manhtai.com)
