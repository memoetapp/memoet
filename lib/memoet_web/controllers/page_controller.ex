defmodule MemoetWeb.PageController do
  use MemoetWeb, :controller
  alias Memoet.Decks

  def index(conn, _params) do
    decks = case Pow.Plug.current_user(conn) do
      nil -> []
      user ->
        %{entries: entries} = Decks.list_decks(%{"user_id" => user.id})
        entries
    end

    %{entries: public_decks} = Decks.list_decks(%{"public" => true})

    render(conn, "index.html", decks: decks, public_decks: public_decks)
  end
end
