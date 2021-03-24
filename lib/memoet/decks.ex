defmodule Memoet.Decks do
  @moduledoc """
  Decks service
  """

  import Ecto.Query

  alias Memoet.Repo
  alias Memoet.Decks.Deck
  alias Memoet.Notes
  alias Memoet.Utils.{MapUtil, RequestUtil}

  @spec list_decks(map) :: map()
  def list_decks(params \\ %{}) do
    {cursor_before, cursor_after, limit} = RequestUtil.get_pagination_params(params)

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

  @spec list_public_decks(map) :: map()
  def list_public_decks(params \\ %{}) do
    {cursor_before, cursor_after, limit} = RequestUtil.get_pagination_params(params)

    params =
      params
      |> Map.merge(%{"public" => true, "source_id" => nil, "listed" => true})

    Deck
    |> where(^filter_where(params))
    |> order_by(desc: :inserted_at)
    |> Repo.paginate(
      before: cursor_before,
      after: cursor_after,
      include_total_count: true,
      cursor_fields: [{:inserted_at, :desc}],
      limit: limit
    )
  end

  @spec get_deck!(binary()) :: Deck.t()
  def get_deck!(id) do
    Deck
    |> Repo.get_by!(id: id)
  end

  @spec get_public_deck!(binary()) :: Deck.t()
  def get_public_deck!(id) do
    Deck
    |> Repo.get_by!(id: id, public: true)
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

      {"listed", value}, dynamic ->
        dynamic([d], ^dynamic and d.listed == ^value)

      {"source_id", nil}, dynamic ->
        dynamic([d], ^dynamic and is_nil(d.source_id))

      {"source_id", value}, dynamic ->
        dynamic([d], ^dynamic and d.source_id == ^value)

      {"q", value}, dynamic ->
        q = "%" <> value <> "%"
        dynamic([d], ^dynamic and ilike(d.name, ^q))

      {_, _}, dynamic ->
        # Not a where parameter
        dynamic
    end)
  end

  def clone_notes(from_deck_id, to_deck_id, to_user_id) do
    Repo.transaction(
      fn ->
        Notes.stream_notes(from_deck_id)
        |> Stream.map(fn note ->
          params =
            MapUtil.from_struct(note)
            |> Map.merge(%{
              "options" => Enum.map(note.options, fn o -> MapUtil.from_struct(o) end),
              "deck_id" => to_deck_id,
              "user_id" => to_user_id
            })

          Notes.create_note_with_card_transaction(params)
          |> Memoet.Repo.transaction()
        end)
        |> Stream.run()
      end,
      timeout: :infinity
    )
  end
end
