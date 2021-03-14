defmodule Memoet.SRS.Sm2 do
  @moduledoc """
  Sm2 API, calling Rust NIF
  """

  use Rustler, otp_app: :memoet, crate: "sm2"
  alias Memoet.SRS.{Config, Scheduler, Card}

  # When your NIF is loaded, it will override this function.
  @spec new(Config.t()) :: Scheduler.t()
  def new(_config), do: error()

  def next_interval(_card, _scheduler, _choice), do: error()
  def next_interval_string(_card, _scheduler, _choice), do: error()

  @spec answer_card(Card.t(), Scheduler.t(), nil) :: Card.t()
  def answer_card(_card, _scheduler, _choice), do: error()

  @spec bury_card(Card.t(), Scheduler.t()) :: Card.t()
  def bury_card(_card, _scheduler), do: error()

  @spec unbury_card(Card.t(), Scheduler.t()) :: Card.t()
  def unbury_card(_card, _scheduler), do: error()

  @spec suspend_card(Card.t(), Scheduler.t()) :: Card.t()
  def suspend_card(_card, _scheduler), do: error()

  @spec unsuspend_card(Card.t(), Scheduler.t()) :: Card.t()
  def unsuspend_card(_card, _scheduler), do: error()

  @spec schedule_card_as_new(Card.t(), Scheduler.t()) :: Card.t()
  def schedule_card_as_new(_card, _scheduler), do: error()

  @spec schedule_card_as_review(Card.t(), Scheduler.t(), integer(), integer()) :: Card.t()
  def schedule_card_as_review(_card, _scheduler, _min_days, _max_days), do: error()

  defp error, do: :erlang.nif_error(:nif_not_loaded)
end
