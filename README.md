# Memoet

## Features

### For life long learner

- Self quizzing (MCQ or type in answer)
- Spaced (SuperMemo2)
- Interleaving (Cross decks learning)

### Extra features

- Assessment tests
- Test sharing
- Collection sharing

## How it works

- Question content is in Markdown format
- There are 2 types of quiz: Multiple Choice & Type Answer
- You can draft your answer & use that as hints when answering the question
- SuperMemo2 algorithm will rate your answer as follow:

  + Wrong answer: Again
  + Partially correct (MCQ: apply for multiple correct answers, TA:
  Levenshtein distance == 1): Hard
  + Correct when revealing drafts: Ok
  + Correct: Easy

- A deck contains multiple cards, maxium 1000. Sm2 will work cross deck or by
  single deck


## API

- CRUD decks
- CRUD cards


## Setup

### Local development

Get `cargo`, `mix`, `node` commands ready. Then:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Install Node.js dependencies with `yarn` inside the `assets` directory
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:3333`](http://localhost:3333) from your browser.


### Deploy to Heroku


```
# Create a Heroku instance for your project
heroku apps:create my_heroku_app

# Set and add the buildpacks for your Heroku app
heroku buildpacks:set https://github.com/emk/heroku-buildpack-rust
heroku buildpacks:add https://github.com/HashNuke/heroku-buildpack-elixir
heroku buildpacks:add https://github.com/gjaldon/heroku-buildpack-phoenix-static

# Create a postgres db
heroku addons:create heroku-postgresql:hobby-dev

# Set environment
heroku config:set SECRET_KEY_BASE=XXXXXXXXXXXXXXXXXXXX

# Deploy
git push heroku master

# Migrate
heroku run "POOL_SIZE=2 mix ecto.migrate --no-compile"
```
