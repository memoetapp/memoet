defmodule Memoet.Notes do
  @moduledoc """
  Note service
  """

  import Ecto.Query

  alias Memoet.Repo
  alias Memoet.Notes.Note
  alias Memoet.Cards
  alias Memoet.Utils.StringUtil

  @spec list_notes(map) :: map()
  def list_notes(params) do
    cursor_before =
      if Map.has_key?(params, "before") and !StringUtil.blank?(params["before"]) do
        params["before"]
      else
        nil
      end

    cursor_after =
      if Map.has_key?(params, "after") and !StringUtil.blank?(params["after"]) do
        params["after"]
      else
        nil
      end

    Note
    |> where(^filter_where(params))
    |> order_by(desc: :updated_at)
    |> Repo.paginate(
      before: cursor_before,
      after: cursor_after,
      include_total_count: true,
      cursor_fields: [{:updated_at, :desc}],
      limit: 10
    )
  end

  @spec stream_notes(binary(), map) :: any()
  def stream_notes(deck_id, _params \\ %{}) do
    Note
    |> where(deck_id: ^deck_id)
    |> order_by(asc: :inserted_at)
    |> Repo.stream()
  end

  @spec get_note!(binary(), binary()) :: Note.t()
  def get_note!(id, user_id) do
    Note
    |> Repo.get_by!(id: id, user_id: user_id)
  end

  @spec get_note!(binary()) :: Note.t()
  def get_note!(id) do
    Note
    |> Repo.get_by!(id: id)
  end

  @spec create_note(map()) :: {:ok, Note.t()} | {:error, Ecto.Changeset.t()}
  def create_note(attrs \\ %{}) do
    %Note{}
    |> Note.changeset(attrs)
    |> Note.clean_options()
    |> Repo.insert()
  end

  @spec update_note(Note.t(), map()) :: {:ok, Note.t()} | {:error, Ecto.Changeset.t()}
  def update_note(%Note{} = note, attrs) do
    note
    |> Note.changeset(attrs)
    |> Note.clean_options()
    |> Repo.update()
  end

  @spec create_note_with_card_transaction(map()) :: Ecto.Multi.t()
  def create_note_with_card_transaction(note_params) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:note, fn _repo, %{} ->
      create_note(note_params)
    end)
    |> Ecto.Multi.run(:card, fn _repo, %{note: note} ->
      card_params =
        note_params
        |> Map.merge(%{"note_id" => note.id})

      Cards.create_card(card_params)
    end)
  end

  @spec delete_note!(binary(), binary()) :: Deck.t()
  def delete_note!(id, user_id) do
    Note
    |> Repo.get_by!(id: id, user_id: user_id)
    |> Repo.delete!()
  end

  @spec filter_where(map) :: Ecto.Query.DynamicExpr.t()
  defp filter_where(attrs) do
    Enum.reduce(attrs, dynamic(true), fn
      {"user_id", value}, dynamic ->
        dynamic([n], ^dynamic and n.user_id == ^value)

      {"deck_id", value}, dynamic ->
        dynamic([n], ^dynamic and n.deck_id == ^value)

      {"q", value}, dynamic ->
        q = "%" <> value <> "%"
        dynamic([n], ^dynamic and ilike(n.title, ^q))

      {_, _}, dynamic ->
        # Not a where parameter
        dynamic
    end)
  end
end
