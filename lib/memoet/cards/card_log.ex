defmodule Memoet.Cards.CardLog do
  @moduledoc """
  Logging for stats
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Memoet.Users.User
  alias Memoet.Cards.Card
  alias Memoet.Decks.Deck

  @srs_fields [:choice, :interval, :last_interval, :ease_factor, :time_answer, :card_type]
  @foreign_key_fields [:user_id, :deck_id, :card_id]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "card_logs" do
    field(:choice, :integer, null: false)
    field(:interval, :integer, null: false)
    field(:last_interval, :integer, null: false)
    field(:ease_factor, :integer, null: false)
    field(:time_answer, :integer, null: false)
    field(:card_type, :integer, null: false)

    belongs_to(:user, User, foreign_key: :user_id, references: :id, type: :binary_id)
    belongs_to(:deck, Deck, foreign_key: :deck_id, references: :id, type: :binary_id)
    belongs_to(:card, Card, foreign_key: :card_id, references: :id, type: :binary_id)

    timestamps()
  end

  def changeset(card, attrs) do
    card
    |> cast(attrs, @srs_fields ++ @foreign_key_fields)
    |> validate_required(@srs_fields ++ @foreign_key_fields)
  end
end
