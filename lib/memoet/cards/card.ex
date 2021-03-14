defmodule Memoet.Cards.Card do
  @moduledoc """
  Card repo
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Memoet.Users.User
  alias Memoet.Cards.{CardTypes, CardQueues}
  alias Memoet.Notes.Note
  alias Memoet.Decks.Deck

  @srs_fields [
    :card_type,
    :card_queue,
    :due,
    :interval,
    :ease_factor,
    :reps,
    :lapses,
    :remaining_steps
  ]
  @required_fields [:user_id, :note_id, :deck_id]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "cards" do
    # SRS fields
    field(:card_type, :integer, default: CardTypes.new())
    field(:card_queue, :integer, default: CardQueues.new())
    field(:due, :integer, default: 0)
    field(:interval, :integer, default: 0)
    field(:ease_factor, :integer, default: 0)
    field(:reps, :integer, default: 0)
    field(:lapses, :integer, default: 0)
    field(:remaining_steps, :integer, default: 0)

    belongs_to(:user, User, foreign_key: :user_id, references: :id, type: :binary_id)
    belongs_to(:note, Note, foreign_key: :note_id, references: :id, type: :binary_id)
    belongs_to(:deck, Deck, foreign_key: :deck_id, references: :id, type: :binary_id)

    timestamps()
  end

  def changeset(card, attrs) do
    card
    |> cast(attrs, @srs_fields ++ @required_fields)
    |> validate_required(@required_fields)
  end

  def srs_changeset(card, attrs) do
    card
    |> cast(attrs, @srs_fields)
  end
end
