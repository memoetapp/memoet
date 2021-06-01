defmodule MemoetWeb.DeckControllerTest do
  use MemoetWeb.ConnCase

  alias Memoet.Repo

  import Memoet.Factory
  import Memoet.TestUtils

  describe "GET /decks/new" do
    setup [:create_user, :log_in]

    test "shows create new deck form", %{conn: conn} do
      conn = get(conn, "/decks/new")
      assert html_response(conn, 200) =~ "Create new deck"
    end
  end

  describe "GET /decks" do
    setup [:create_user, :log_in]

    test "shows empty screen if no decks", %{conn: conn} do
      conn = get(conn, "/decks")
      assert html_response(conn, 200) =~ "No decks is created yet"
    end

    test "lists all your decks", %{conn: conn, user: user} do
      insert(:deck, user: user, name: "Geography deck")
      conn = get(conn, "/decks")

      assert html_response(conn, 200) =~ "Geography deck"
    end
  end

  describe "GET /decks/:deck_id" do
    setup [:create_user, :log_in, :create_deck]

    test "lists one of your decks", %{conn: conn, deck: deck} do
      conn = get(conn, "/decks/" <> deck.id)

      assert html_response(conn, 200) =~ deck.name
    end
  end

  describe "POST /decks" do
    setup [:create_user, :log_in]

    test "create new deck", %{conn: conn} do
      conn =
        post(conn, "/decks", %{
          "deck" => %{"name" => "History deck"}
        })

      deck_detail = redirected_to(conn)
      assert String.starts_with?(deck_detail, "/decks/")
      assert Repo.exists?(Memoet.Decks.Deck, name: "History deck")
    end
  end
end
