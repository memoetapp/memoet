defmodule Memoet.Repo do
  use Ecto.Repo,
    otp_app: :memoet,
    adapter: Ecto.Adapters.Postgres

  use Paginator
end
