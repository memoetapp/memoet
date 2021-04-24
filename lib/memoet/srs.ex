defmodule Memoet.SRS do
  @moduledoc """
  SRS service
  """
  alias Memoet.SRS.Sm2
  alias Memoet.SRS.{Scheduler, Config}
  alias Memoet.Users.SrsConfig
  alias Memoet.Users

  @spec get_scheduler(String.t()) :: Scheduler.t()
  def get_scheduler(user_id) do
    cache_key = get_cache_key(user_id)

    {_, cache_value} =
      Cachex.fetch(
        :memoet_cachex,
        cache_key,
        fn _key -> {:commit, get_scheduler_from_db(user_id)} end
      )

    cache_value
  end

  @spec set_scheduler(String.t(), SrsConfig.t()) :: :ok
  def set_scheduler(user_id, srs_config) do
    config = struct(Config, Map.from_struct(srs_config))
    day_cut_off = Memoet.Timezones.day_cut_off(srs_config.timezone)
    scheduler = Sm2.new(config, day_cut_off)
    Cachex.put(:memoet_cachex, get_cache_key(user_id), scheduler)
    :ok
  end

  @spec get_cache_key(String.t()) :: String.t()
  defp get_cache_key(user_id) do
    "scheduler_" <> user_id
  end

  @spec get_scheduler_from_db(String.t()) :: Scheduler.t()
  def get_scheduler_from_db(user_id) do
    srs_config = Users.get_srs_config(user_id)
    config = struct(Config, Map.from_struct(srs_config))
    day_cut_off = Memoet.Timezones.day_cut_off(srs_config.timezone)
    Sm2.new(config, day_cut_off)
  end
end
