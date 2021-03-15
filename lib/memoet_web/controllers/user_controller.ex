defmodule MemoetWeb.UserController do
  use MemoetWeb, :controller

  @spec show(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def show(conn, _params) do
    user = Pow.Plug.current_user(conn)
    render(conn, "show.html", user: user)
  end
end
