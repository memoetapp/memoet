defmodule Memoet.Decks.Deck do
  @moduledoc """
  Note model
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Memoet.Notes.Note
  alias Memoet.Decks.Colors

  @name_limit 250
  @code_limit 250

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "decks" do
    field(:name, :string, null: false)
    field(:code, :string, null: false)

    field(:color, :string, null: false, default: Colors.gray())

    has_many(:notes, Note)
    belongs_to(:user, User, foreign_key: :user_id, references: :id, type: :binary_id)

    timestamps()
  end

  def changeset(note_or_changeset, attrs) do
    note_or_changeset
    |> cast(attrs, [
      :name,
      :code,
      :color,
      :user_id,
    ])
    |> validate_length(:name, max: @name_limit)
    |> validate_length(:code, max: @code_limit)
    |> validate_inclusion(:type, [
      Type.multiple_choice(),
      Type.type_answer(),
    ])
    |> validate_required([:title, :content, :type, :user_id, :deck_id])
  end
end
