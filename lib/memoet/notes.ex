defmodule Memoet.Notes do
  @moduledoc """
  Note service
  """

  import Ecto.Query

  alias Memoet.Repo
  alias Memoet.Notes.Note
  alias Memoet.Cards

  @spec list_notes(binary(), map) :: [Note.t()]
  def list_notes(deck_id, _params \\ %{}) do
    Note
    |> where(deck_id: ^deck_id)
    |> order_by(asc: :inserted_at)
    |> Repo.all()
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
end
