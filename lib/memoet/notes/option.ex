defmodule Memoet.Notes.Option do
  @moduledoc """
  Option model
  """

  use Ecto.Schema
  import Ecto.Changeset

  @content_limit 2_000

  embedded_schema do
    field(:content, :string)
    field(:correct, :boolean)

    field(:image, :string)
  end

  def changeset(item, attrs) do
    item
    |> cast(attrs, [:content, :correct, :image])
    |> validate_length(:content, max: @content_limit)
    |> validate_length(:image, max: @content_limit)
  end
end
