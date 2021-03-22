defmodule MemoetWeb.DeckControllerTest do
  use MemoetWeb.ConnCase
  import Memoet.TestUtils

  describe "GET /decks/new" do
    setup [:create_user, :log_in]

    test "shows create new deck form", %{conn: conn} do
      conn = get(conn, "/decks/new")
      assert html_response(conn, 200) =~ "Create new deck"
    end
  end
end
