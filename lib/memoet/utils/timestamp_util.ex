defmodule Memoet.Utils.TimestampUtil do
  @moduledoc """
  Time functions
  """

  def now(unit \\ :second) do
    DateTime.utc_now()
    |> DateTime.to_unix(unit)
  end

  def today(unit \\ :second) do
    s =
      DateTime.utc_now()
      |> DateTime.to_unix(unit)

    trunc(s / 86_400)
  end
end
