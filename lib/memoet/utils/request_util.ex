defmodule Memoet.Req do
  @moduledoc """
  Request utilities
  """
  @max_limit 100

  alias Memoet.Str

  def get_pagination_params(params) do
    cursor_before =
      if Map.has_key?(params, "before") and !Str.blank?(params["before"]) do
        params["before"]
      else
        nil
      end

    cursor_after =
      if Map.has_key?(params, "after") and !Str.blank?(params["after"]) do
        params["after"]
      else
        nil
      end

    limit =
      if Map.has_key?(params, "limit") and !Str.blank?(params["limit"]) do
        {number, _} = Integer.parse(to_string(params["limit"]))
        number
      else
        10
      end

    limit = min(limit, @max_limit)

    {cursor_before, cursor_after, limit}
  end
end
