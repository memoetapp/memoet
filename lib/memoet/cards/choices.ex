defmodule Memoet.Cards.Choices do
  @again 1
  @hard 2
  @ok 3
  @easy 4

  def again, do: @again
  def hard, do: @hard
  def ok, do: @ok
  def easy, do: @easy

  def from_atom(atom) do
    case atom do
      :again -> @again
      :hard -> @hard
      :easy -> @easy
      _ -> @ok
    end
  end

  def to_atom(type) do
    case type do
      @again -> :again
      @hard -> :hard
      @easy -> :easy
      _ -> :ok
    end
  end
end
