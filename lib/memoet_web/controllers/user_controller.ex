defmodule MemoetWeb.UserController do
  use MemoetWeb, :controller

  alias Memoet.{Users, Users.SrsConfig, SRS}

  @spec show(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def show(conn, _params) do
    user = Pow.Plug.current_user(conn)
    render(conn, "show.html", user: user)
  end
end
