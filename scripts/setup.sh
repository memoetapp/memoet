#!/bin/bash
# This script is for deploying Memoet to Ubuntu 18.04 server, use it at your own risk
sudo apt update

# Rust
sudo apt install -y build-essential
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Elixir
wget -O- https://packages.erlang-solutions.com/ubuntu/erlang_solutions.asc | sudo apt-key add -
echo "deb https://packages.erlang-solutions.com/ubuntu bionic contrib" | sudo tee /etc/apt/sources.list.d/rabbitmq.list
sudo apt update
sudo apt install esl-erlang
sudo apt install elixir

# Node
curl -fsSL https://deb.nodesource.com/setup_14.x | sudo -E bash -
sudo apt install -y nodejs

# Postgres
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt update
sudo apt install postgresql-13

# Postgres create user
# sudo -u postgres psql
# create database memoet;
# create user memoet with encrypted password 'memoet';
# grant all privileges on database memoet to memoet;

# Power to open lower ports (80)
sudo setcap CAP_NET_BIND_SERVICE=+eip /usr/lib/erlang/erts-11.1.7/bin/beam.smp

# Clone
git clone https://github.com/manhtai/memoet.git
cd memoet/

mix deps.get
MIX_ENV=prod mix compile

# In assets folder
# npm install
# npm run deploy

mix phx.digest
MIX_ENV=prod mix ecto.migrate

# Start!
PORT=80 MIX_ENV=prod elixir --erl "-detached" -S mix phx.server --no-compile
