defmodule MemoetWeb.CollectionControllerTest do
  use MemoetWeb.ConnCase

  import Memoet.Factory
  import Memoet.TestUtils

  describe "GET /today" do
    setup [:create_user, :log_in]

    test "shows empty today", %{conn: conn} do
      conn = get(conn, "/today")
      assert html_response(conn, 200) =~ "Today collection"
      assert html_response(conn, 200) =~ "No decks is created"
    end

    test "shows all the decks", %{conn: conn, user: user} do
      insert(:deck, user: user, name: "Geography deck")
      conn = get(conn, "/decks")

      assert html_response(conn, 200) =~ "Geography deck"
    end
  end

  describe "GET /today/practice" do
    setup [:create_user, :log_in]

    test "shows empty notes to practice", %{conn: conn} do
      conn = get(conn, "/today/practice")
      assert html_response(conn, 200) =~ "No more notes"
    end
  end
end
