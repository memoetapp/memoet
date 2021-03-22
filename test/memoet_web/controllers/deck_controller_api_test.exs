defmodule MemoetWeb.DeckControllerAPITest do
  use MemoetWeb.ConnCase

  alias Memoet.Repo

  import Memoet.Factory
  import Memoet.TestUtils

  describe "GET /api/decks" do
    setup [:create_user, :log_in]

    test "shows empty screen if no decks", %{conn: conn} do
      conn = get(conn, "/api/decks")
      assert json_response(conn, 200)["data"] == []
    end

    test "lists all your decks", %{conn: conn, user: user} do
      insert(:deck, user: user, name: "Geography deck")
      conn = get(conn, "/api/decks")

      assert length(json_response(conn, 200)["data"]) == 1
    end
  end

  describe "GET /api/decks/:deck_id" do
    setup [:create_user, :log_in, :create_deck]

    test "lists one of your decks", %{conn: conn, deck: deck} do
      conn = get(conn, "/api/decks/" <> deck.id)

      assert json_response(conn, 200)["data"]["name"] == deck.name
    end
  end

  describe "POST /api/decks" do
    setup [:create_user, :log_in]

    test "create new deck", %{conn: conn} do
      conn =
        post(conn, "/api/decks", %{
          "name" => "History deck"
        })

      assert json_response(conn, 200)["data"]["name"] == "History deck"
      assert Repo.exists?(Memoet.Decks.Deck, name: "History deck")
    end
  end
end
