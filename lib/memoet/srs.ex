defmodule Memoet.SRS do
  @moduledoc """
  SRS service
  """
  alias Memoet.SRS.Sm2
  alias Memoet.SRS.{Scheduler, Config}
  alias Memoet.Users.SrsConfig
  alias Memoet.{Users, Utils.TimestampUtil}

  @spec get_scheduler(String.t()) :: Scheduler.t()
  def get_scheduler(user_id) do
    cache_key = get_cache_key(user_id)

    {_, srs_config} =
      Cachex.fetch(
        :memoet_cachex,
        cache_key,
        fn _key -> {:commit, Users.get_srs_config(user_id)} end
      )

    config = struct(Config, Map.from_struct(srs_config))
    day_cut_off = TimestampUtil.day_cut_off(srs_config.timezone)
    day_today = TimestampUtil.days_from_epoch(srs_config.timezone)
    Sm2.new(config, day_cut_off, day_today)
  end

  @spec set_config(String.t(), SrsConfig.t()) :: :ok
  def set_config(user_id, srs_config) do
    Cachex.put(:memoet_cachex, get_cache_key(user_id), srs_config)
    :ok
  end

  @spec get_cache_key(String.t()) :: String.t()
  defp get_cache_key(user_id) do
    "srs_config_" <> user_id
  end
end
