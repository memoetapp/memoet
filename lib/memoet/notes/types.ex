defmodule Memoet.Notes.Types do
  @moduledoc false

  @multiple_choice "multiple_choice"
  @type_answer "type_answer"

  def multiple_choice, do: @multiple_choice
  def type_answer, do: @type_answer

  def detect(type) do
    type =
      type
      |> String.trim()
      |> String.replace(" ", "_")
      |> String.downcase()

    if type == @type_answer do
      @type_answer
    else
      @multiple_choice
    end
  end
end
