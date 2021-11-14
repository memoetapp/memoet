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
config :logger,
  backends: [:console, Sentry.LoggerBackend],
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :mime, :types, %{
  "text/csv" => ["csv", "tsv", "txt"]
}

# Read .env
try do
  File.stream!("./.env")
  |> Stream.map(&String.trim_trailing/1)
  |> Enum.each(fn line ->
    line
    |> String.replace("export ", "")
    |> String.split("=", parts: 2)
    |> Enum.reduce(fn value, key ->
      System.put_env(key, value)
    end)
  end)
rescue
  _ -> IO.puts("no .env file found!")
end

# Uploaders
config :waffle,
  version_timeout: 60_000,
  storage: Waffle.Storage.S3,
  asset_host: System.get_env("AWS_ASSET_HOST"),
  bucket: System.get_env("AWS_BUCKET_NAME")

config :ex_aws,
  json_codec: Jason,
  access_key_id: System.get_env("AWS_ACCESS_KEY_ID"),
  secret_access_key: System.get_env("AWS_SECRET_ACCESS_KEY"),
  region: System.get_env("AWS_REGION")

# Job worker
config :memoet, Oban,
  repo: Memoet.Repo,
  plugins: [
    Oban.Plugins.Pruner
  ],
  queues: [default: 10, pro: 50]

# Mailers
sib_api_key = System.get_env("SENDINBLUE_API_KEY")

if sib_api_key != nil do
  config :memoet, Memoet.Emails,
    adapter: Swoosh.Adapters.Sendinblue,
    api_key: sib_api_key
else
  config :memoet, Memoet.Emails, adapter: Swoosh.Adapters.Gmail
end

# Auth
config :memoet, :pow,
  user: Memoet.Users.User,
  repo: Memoet.Repo,
  web_module: MemoetWeb,
  extensions: [PowResetPassword, PowPersistentSession],
  controller_callbacks: Pow.Extension.Phoenix.ControllerCallbacks,
  mailer_backend: MemoetWeb.Pow.Mailer,
  cache_store_backend: Pow.Postgres.Store

config :pow, Pow.Postgres.Store, repo: Memoet.Repo

# Monitoring
config :sentry,
  dsn: System.get_env("SENTRY_DSN"),
  included_environments: [:prod],
  environment_name: Mix.env()

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
