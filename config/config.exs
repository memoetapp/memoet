# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :repeatnotes,
  ecto_repos: [RepeatNotes.Repo]

# Configures the endpoint
config :repeatnotes, RepeatNotesWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "v1DV0Du47Is5/EZiRXMCO5h1pp7reS1kR8IMjdH9UH9QqMjED3b/LdwKuwWlC+TG",
  render_errors: [view: RepeatNotesWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: RepeatNotes.PubSub,
  live_view: [signing_salt: "yWHiYT3q"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

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


# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
