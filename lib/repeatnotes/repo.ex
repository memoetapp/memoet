defmodule RepeatNotes.Repo do
  use Ecto.Repo,
    otp_app: :repeatnotes,
    adapter: Ecto.Adapters.Postgres
end
