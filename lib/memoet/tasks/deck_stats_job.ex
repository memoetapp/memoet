defmodule Memoet.Tasks.DeckStatsJob do
  @moduledoc """
  Run stats job for deck
  """

  alias Memoet.Decks
  require Logger

  use Oban.Worker,
    queue: :default,
    priority: 3,
    max_attempts: 1,
    tags: ["stats"],
    unique: [fields: [:args], keys: [:deck_id], period: 60]

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"deck_id" => deck_id} = _args}) do
    Decks.calculate_deck_stats(deck_id)
    :ok
  end
end

