defmodule MemoetWeb.PageController do
  use MemoetWeb, :controller
  alias Memoet.Decks
  alias Memoet.Collections

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
        today_collection = Collections.get_today_collection(user.id)

        render(conn, "index.html", decks: decks, metadata: metadata, collection: today_collection)
    end
  end
end
