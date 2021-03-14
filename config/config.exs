# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :memoet,
  ecto_repos: [Memoet.Repo]

# Configures the endpoint
config :memoet, MemoetWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "zoKAHRc9F8QPfx/Tx/CXJA12dY2RaVK3nC151hcXALgZJmOSMHswzs4tF0x/YXyj",
  render_errors: [view: MemoetWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Memoet.PubSub,
  live_view: [signing_salt: "cPUFUjaA"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Auth
config :memoet, :pow,
  user: Memoet.Users.User,
  repo: Memoet.Repo,
  web_module: MemoetWeb,
  extensions: [PowResetPassword],
  controller_callbacks: Pow.Extension.Phoenix.ControllerCallbacks,
  session_ttl_renewal: :timer.hours(24 * 7),
  cache_store_backend: Pow.Postgres.Store

config :pow, Pow.Postgres.Store, repo: Memoet.Repo

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
