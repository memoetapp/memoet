defmodule Memoet.Decks.ImportError do
  defexception [:message, :line, :column]
end
