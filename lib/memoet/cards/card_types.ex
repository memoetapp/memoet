defmodule Memoet.Cards.CardTypes do
  @new 0
  @learn 1
  @review 2
  @relearn 3

  def new, do: @new
  def learn, do: @learn
  def review, do: @review
  def relearn, do: @relearn

  def from_atom(atom) do
    case atom do
      :learn -> @learn
      :review -> @review
      :relearn -> @relearn
      _ -> @new
    end
  end

  def to_atom(type) do
    case type do
      @learn -> :learn
      @review -> :review
      @relearn -> :relearn
      _ -> :new
    end
  end
end
