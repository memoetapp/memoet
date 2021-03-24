defmodule Memoet.Utils.RequestUtil do
  @moduledoc """
  Request utilities
  """
  @max_limit 100

  alias Memoet.Utils.StringUtil

  def get_pagination_params(params) do
    cursor_before =
      if Map.has_key?(params, "before") and !StringUtil.blank?(params["before"]) do
        params["before"]
      else
        nil
      end

    cursor_after =
      if Map.has_key?(params, "after") and !StringUtil.blank?(params["after"]) do
        params["after"]
      else
        nil
      end

    limit =
      if Map.has_key?(params, "limit") and !StringUtil.blank?(params["limit"]) do
        Integer.parse(to_string(params["limit"]))
      else
        10
      end

    limit = min(limit, @max_limit)

    {cursor_before, cursor_after, limit}
  end
end
