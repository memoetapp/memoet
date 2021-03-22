#!/bin/bash
git pull origin master
mix deps.get
MIX_ENV=prod mix compile

# Assets
(cd assets/ && npm install && npm run deploy)
MIX_ENV=prod mix phx.digest

(sudo lsof -ti :80 | xargs kill) || true
PORT=80 MIX_ENV=prod elixir --erl "-detached" -S mix phx.server --no-compile
