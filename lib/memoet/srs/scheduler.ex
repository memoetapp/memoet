defmodule Memoet.SRS.Scheduler do
  alias Memoet.SRS.Config

  defstruct config: %Config{},
            day_cut_off: 0,
            day_today: 0
end
