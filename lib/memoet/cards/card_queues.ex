defmodule Memoet.Cards.CardQueues do
  @new 0
  @learn 1
  @review 2
  @day_learn 3
  @suspended -1
  @buried -2

  def new, do: @new
  def learn, do: @learn
  def review, do: @review
  def day_learn, do: @day_learn
  def suspended, do: @suspended
  def buried, do: @buried

  def from_atom(atom) do
    case atom do
      :learn -> @learn
      :review -> @review
      :day_learn -> @day_learn
      :suspended -> @suspended
      :buried -> @buried
      _ -> @new
    end
  end

  def to_atom(queue) do
    case queue do
      @learn -> :learn
      @review -> :review
      @day_learn -> :day_learn
      @suspended -> :suspended
      @buried -> :buried
      _ -> :new
    end
  end
end
