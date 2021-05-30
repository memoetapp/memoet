defmodule MemoetWeb.PageController do
  use MemoetWeb, :controller
  alias Memoet.Decks
  alias Memoet.SRS
  alias Memoet.Collections

  def index(conn, _params) do
    case Pow.Plug.current_user(conn) do
      nil ->
        %{entries: public_decks} = Decks.list_public_decks(%{"limit" => 3})

        conn
        |> assign(:width_full, true)
        |> render("landing.html", public_decks: public_decks)

      user ->
        %{entries: decks} = Decks.list_decks(%{"user_id" => user.id, "limit" => 5})

        timezone = SRS.get_config(user.id).timezone
        today_collection = Collections.get_today_collection(user.id)
        stats = Decks.user_stats(user.id, timezone)
        practices = for d <- -29..0, do: stats.practice_by_date[d] || 0

        render(
          conn,
          "index.html",
          decks: decks,
          practices: practices,
          collection: today_collection
        )
    end
  end
end
