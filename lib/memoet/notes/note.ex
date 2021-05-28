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
  alias Memoet.Utils.StringUtil

  @title_limit 250
  @content_limit 2_500

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "notes" do
    field(:title, :string, null: false)
    field(:image, :string, null: true)

    field(:content, :string, null: false, default: "")
    field(:type, :string, null: false, default: Types.flash_card())

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
      :image,
      :content,
      :type,
      :hint,
      :user_id,
      :deck_id
    ])
    |> cast_embed(:options)
    |> validate_length(:title, max: @title_limit)
    |> validate_length(:content, max: @content_limit)
    |> validate_inclusion(:type, [
      Types.flash_card(),
      Types.multiple_choice(),
      Types.type_answer()
    ])
    |> validate_required([:title, :type, :user_id, :deck_id])
  end

  def clean_options(changeset) do
    update_change(changeset, :options, fn changesets ->
      changesets
      |> Enum.filter(fn option -> not StringUtil.blank?(get_field(option, :content)) end)
    end)
  end
end
