defmodule Memoet.Decks do
  @moduledoc """
  Decks service
  """

  import Ecto.Query

  alias Memoet.Repo
  alias Memoet.Decks.Deck

  @spec list_decks(map) :: map()
  def list_decks(params \\ %{}) do
    cursor_before =
      if Map.has_key?(params, "before") and params["before"] != "" do
        params["before"]
      else
        nil
      end

    cursor_after =
      if Map.has_key?(params, "after") and params["after"] != "" do
        params["after"]
      else
        nil
      end

    limit =
      if Map.has_key?(params, "limit") do
        params["limit"]
      else
        10
      end

    Deck
    |> where(^filter_where(params))
    |> order_by(desc: :updated_at)
    |> Repo.paginate(
      before: cursor_before,
      after: cursor_after,
      include_total_count: true,
      cursor_fields: [{:updated_at, :desc}],
      limit: limit
    )
  end

  @spec get_deck!(binary()) :: Deck.t()
  def get_deck!(id) do
    Deck
    |> Repo.get_by!(id: id)
  end

  def calculate_deck_stats(id) do
    # This function will calculate decks statistics, but doing nothing for now
    Deck
    |> Repo.get_by!(id: id)
    |> Deck.stats_changeset(%{updated_at: Timex.now()})
    |> Repo.update()
  end

  @spec delete_deck!(binary(), binary()) :: Deck.t()
  def delete_deck!(id, user_id) do
    Deck
    |> Repo.get_by!(id: id, user_id: user_id)
    |> Repo.delete!()
  end

  @spec get_deck!(binary(), binary()) :: Deck.t()
  def get_deck!(id, user_id) do
    Deck
    |> Repo.get_by!(id: id, user_id: user_id)
  end

  @spec create_deck(map()) :: {:ok, Deck.t()} | {:error, Ecto.Changeset.t()}
  def create_deck(attrs \\ %{}) do
    %Deck{}
    |> Deck.changeset(attrs)
    |> Repo.insert()
  end

  @spec update_deck(Deck.t(), map()) :: {:ok, Deck.t()} | {:error, Ecto.Changeset.t()}
  def update_deck(%Deck{} = deck, attrs) do
    deck
    |> Deck.changeset(attrs)
    |> Repo.update()
  end

  @spec filter_where(map) :: Ecto.Query.DynamicExpr.t()
  defp filter_where(attrs) do
    Enum.reduce(attrs, dynamic(true), fn
      {"user_id", value}, dynamic ->
        dynamic([d], ^dynamic and d.user_id == ^value)

      {"public", value}, dynamic ->
        dynamic([d], ^dynamic and d.public == ^value)

      {_, _}, dynamic ->
        # Not a where parameter
        dynamic
    end)
  end
end
