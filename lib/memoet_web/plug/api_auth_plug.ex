defmodule MemoetWeb.APIAuthPlug do
  @moduledoc false

  use Pow.Plug.Base

  alias Memoet.Users
  alias Plug.Conn

  @impl true
  def fetch(conn, _config) do
    user =
      fetch_auth_token(conn)
      |> get_user_from_token()

    {conn, user}
  end

  @impl true
  def create(conn, user, _config) do
    {conn, user}
  end

  @impl true
  def delete(conn, _config) do
    fetch_auth_token(conn)
    |> delete_token_cache()

    conn
  end

  defp delete_token_cache(token) do
    Cachex.del(:memoet_cachex, get_token_cache(token))
  end

  defp get_user_from_token(token) do
    {_, user} =
      Cachex.fetch(
        :memoet_cachex,
        get_token_cache(token),
        fn _key -> {:commit, Users.find_user_by_token(token)} end
      )

    user
  end

  defp fetch_auth_token(conn) do
    with [token | _rest] <- Conn.get_req_header(conn, "authorization"),
         user_token <- String.replace_leading(token, "Bearer ", "") do
      user_token
    else
      _any -> nil
    end
  end

  defp get_token_cache(user_token) do
    "user_token_" <> user_token
  end
end
