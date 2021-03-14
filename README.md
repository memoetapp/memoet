# Memoet

> SRS for quiz, learning should be more fun!


## Local setup

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Install Node.js dependencies with `yarn` inside the `assets` directory
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.


## Deploy to Heroku


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
