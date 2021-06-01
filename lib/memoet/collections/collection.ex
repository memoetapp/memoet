defmodule Memoet.Collections.Collection do
  @moduledoc """
  Collection model, contains many decks to support interleave learning
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Memoet.Collections.DeckCollection
  alias Memoet.Users.User

  @name_limit 250

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "collections" do
    field(:name, :string, null: false, default: "Today")

    belongs_to(:user, User, foreign_key: :user_id, references: :id, type: :binary_id)

    has_many(:decks_collections, DeckCollection, on_replace: :delete)
    has_many(:decks, through: [:decks_collections, :deck], on_replace: :delete)

    timestamps()
  end

  def changeset(col_or_changeset, attrs) do
    col_or_changeset
    |> cast(attrs, [:name, :user_id])
    |> validate_required([:name, :user_id])
    |> validate_length(:name, max: @name_limit)
    |> cast_assoc(:decks_collections)
  end
end
