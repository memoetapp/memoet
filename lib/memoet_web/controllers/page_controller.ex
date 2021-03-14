defmodule MemoetWeb.PageController do
  use MemoetWeb, :controller

  def index(conn, _params) do
    user = Pow.Plug.current_user(conn)

    case user do
      nil -> render(conn, "index.html")
      _ -> redirect(conn, to: "/decks")
    end
  end
end
