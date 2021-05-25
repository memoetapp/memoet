defmodule Memoet.Notes.Types do
  @moduledoc false

  @multiple_choice "multiple_choice"
  @type_answer "type_answer"
  @flash_card "flash_card"

  def multiple_choice, do: @multiple_choice
  def type_answer, do: @type_answer
  def flash_card, do: @flash_card

  def detect(type) do
    type =
      type
      |> String.trim()
      |> String.replace(" ", "_")
      |> String.downcase()

    case type do
      @type_answer -> @type_answer
      @multiple_choice -> @multiple_choice
      _ -> @flash_card
    end
  end
end
