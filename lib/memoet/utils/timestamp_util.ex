defmodule Memoet.Utils.TimestampUtil do
  @moduledoc """
  Time functions
  """

  def now(unit \\ :second) do
    DateTime.utc_now()
    |> DateTime.to_unix(unit)
  end

  def days_from_epoch(timezone) do
    Timex.now(timezone)
    |> Date.diff(~D[1970-01-01])
  end

  def days_from_epoch() do
    days_from_epoch("Etc/Greenwich")
  end

  def day_cut_off(timezone) do
    Timex.now(timezone)
    |> Timex.end_of_day()
    |> DateTime.to_unix()
  end

  def day_cut_off() do
    day_cut_off("Etc/Greenwich")
  end
end
