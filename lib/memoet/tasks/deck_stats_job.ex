defmodule Memoet.Tasks.DeckStatsJob do
  @moduledoc """
  Run stats job for deck
  """

  require Logger

  use Oban.Worker,
    queue: :default,
    priority: 3,
    max_attempts: 1,
    tags: ["deck"],
    unique: [fields: [:args], keys: [:deck_id], period: 60]

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"deck_id" => _deck_id} = _args}) do
    :ok
  end
end
