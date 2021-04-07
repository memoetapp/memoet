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
    field(:listed, :boolean, null: false, default: false)

    field(:learning_order, :string, null: false, default: "random")

    belongs_to(:user, User, foreign_key: :user_id, references: :id, type: :binary_id)
    belongs_to(:deck, Deck, foreign_key: :source_id, references: :id, type: :binary_id)

    has_many(:notes, Note)

    timestamps()
  end

  def changeset(deck_or_changeset, attrs) do
    deck_or_changeset
    |> cast(attrs, [
      :name,
      :public,
      :learning_order,
      :source_id,
      :user_id
    ])
    |> validate_length(:name, max: @name_limit)
    |> validate_required([:name, :public, :user_id])
    |> validate_inclusion(:learning_order, [
      "random",
      "first_created"
    ])
  end

  def stats_changeset(deck, attrs) do
    deck
    |> cast(attrs, [:updated_at])
  end
end
