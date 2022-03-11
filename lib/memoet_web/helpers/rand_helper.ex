defmodule MemoetWeb.RandHelper do
  @moduledoc """
  Shuffle things around
  """
  alias Memoet.Notes.Note

  @spec may_shuffle(Note.t(), boolean) :: Note.t()
  def may_shuffle(note, yes) do
    if yes do
      %Note{note | options: Enum.shuffle(note.options)}
    else
      note
    end
  end
end
