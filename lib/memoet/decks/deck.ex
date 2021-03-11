defmodule Memoet.Decks.Deck do
  @moduledoc """
  Deck model
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Memoet.Notes.Note
  alias Memoet.Decks.Deck
  alias Memoet.Users.User

  @name_limit 250

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "decks" do
    field(:name, :string, null: false)
    field(:public, :boolean, null: false, default: false)

    belongs_to(:user, User, foreign_key: :user_id, references: :id, type: :binary_id)
    belongs_to(:deck, Deck, foreign_key: :source_id, references: :id, type: :binary_id)

    has_many(:notes, Note)

    timestamps()
  end

  def changeset(note_or_changeset, attrs) do
    note_or_changeset
    |> cast(attrs, [
      :name,
      :public,
      :source_id,
      :user_id,
    ])
    |> validate_length(:name, max: @name_limit)
    |> validate_required([:name, :public, :user_id])
  end
end
