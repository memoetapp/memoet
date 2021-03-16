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
