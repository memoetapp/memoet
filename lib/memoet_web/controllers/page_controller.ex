defmodule MemoetWeb.PageController do
  use MemoetWeb, :controller
  alias Memoet.Decks

  def index(conn, _params) do
    case Pow.Plug.current_user(conn) do
      nil ->
        %{entries: public_decks} = Decks.list_public_decks(%{"limit" => 3})

        conn
        |> assign(:width_full, true)
        |> render("landing.html", public_decks: public_decks)

      user ->
        %{entries: decks, metadata: metadata} =
          Decks.list_decks(%{"user_id" => user.id, "limit" => 5})

        render(conn, "index.html", decks: decks, metadata: metadata)
    end
  end
end
