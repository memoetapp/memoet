defmodule Memoet.Notes.Note do
  @moduledoc """
  Note model
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Memoet.Notes.{Option, Types}
  alias Memoet.Users.User
  alias Memoet.Cards.Card
  alias Memoet.Decks.Deck

  @title_limit 250
  @content_limit 2_500

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "notes" do
    field(:title, :string)
    field(:content, :string)

    field(:type, :string, null: false, default: Types.multiple_choice())
    embeds_many(:options, Option, on_replace: :delete)

    field(:hint, :string)

    has_many(:cards, Card)
    belongs_to(:user, User, foreign_key: :user_id, references: :id, type: :binary_id)
    belongs_to(:deck, Deck, foreign_key: :deck_id, references: :id, type: :binary_id)

    timestamps()
  end

  def changeset(note_or_changeset, attrs) do
    note_or_changeset
    |> cast(attrs, [
      :title,
      :content,
      :type,
      :hint,
      :user_id,
      :deck_id,
    ])
    |> cast_embed(:options)
    |> validate_length(:title, max: @title_limit)
    |> validate_length(:content, max: @content_limit)
    |> validate_inclusion(:type, [
      Types.multiple_choice(),
      Types.type_answer(),
    ])
    |> validate_required([:title, :content, :type, :user_id, :deck_id])
  end

  def clean_options(changeset) do
    options = get_field(changeset, :options)
              |> Enum.filter(fn option -> option.content != nil end)
    put_change(changeset, :options, options)
  end
end
