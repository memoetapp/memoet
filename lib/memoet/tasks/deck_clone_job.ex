defmodule Memoet.Tasks.DeckCloneJob do
  @moduledoc """
  Run clone job for deck
  """

  alias Memoet.Decks

  require Logger

  use Oban.Worker,
    queue: :default,
    priority: 3,
    max_attempts: 1,
    tags: ["deck"],
    unique: [fields: [:args], keys: [:from_deck_id, :to_deck_id], period: 60]

  @impl Oban.Worker
  def perform(%Oban.Job{
        args:
          %{
            "from_deck_id" => from_deck_id,
            "to_deck_id" => to_deck_id,
            "to_user_id" => to_user_id
          } = _args
      }) do
    Decks.clone_notes(from_deck_id, to_deck_id, to_user_id)
    :ok
  end
end
