defmodule MemoetWeb.Plugs.AdminUserAuthPlug do
  import Plug.Conn

  def init(options), do: options

  def call(conn, _opts) do
    user = Pow.Plug.current_user(conn)
    is_admin_user = System.get_env("ADMIN_USERS", "")
                    |> String.split(",")
                    |> Enum.any?(fn email -> email == user.email end)

    case is_admin_user  do
      true ->
        conn
      false ->
        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(403, "403 Forbidden")
        |> halt
    end
  end
end
