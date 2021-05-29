defmodule Memoet.Collections.DeckCollection do
  @moduledoc """
  Mediate model for many-to-many relation between deck & collection
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Memoet.{Collections.Collection, Users.User, Decks.Deck}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "decks_collections" do
    belongs_to(:collection, Collection)
    belongs_to(:deck, Deck)
    belongs_to(:user, User, foreign_key: :user_id, references: :id, type: :binary_id)

    timestamps()
  end

  @doc false
  def changeset(schema, attrs) do
    schema
    |> cast(attrs, [:deck_id, :collection_id, :user_id])
    |> validate_required([:deck_id, :collection_id, :user_id])
    |> cast_assoc(:deck, require: true)
    |> cast_assoc(:collection, require: true)
  end
end
