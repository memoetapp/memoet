defmodule MemoetWeb.NoteControllerAPITest do
  use MemoetWeb.ConnCase

  alias Memoet.Repo

  import Memoet.Factory
  import Memoet.TestUtils

  describe "GET /api/decks/:deck_id/notes" do
    setup [:create_user, :log_in, :create_deck]

    test "shows empty screen if no notes", %{conn: conn, deck: deck} do
      conn = get(conn, "/api/decks/" <> deck.id <> "/notes")
      assert json_response(conn, 200)["data"] == []
    end

    test "lists all your notes", %{conn: conn, deck: deck} do
      insert(:note, deck: deck, title: "Geography note")
      conn = get(conn, "/api/decks/" <> deck.id <> "/notes")

      assert List.first(json_response(conn, 200)["data"])["title"] == "Geography note"
    end
  end

  describe "POST /api/decks/:deck_id/notes" do
    setup [:create_user, :log_in, :create_deck]

    test "create new note", %{conn: conn, deck: deck} do
      link_notes = "/api/decks/" <> deck.id <> "/notes"
      conn =
        post(conn, link_notes, %{
          "note" => %{
            "title" => "History note",
            "content" => ""
          }
        })

      assert json_response(conn, 200)["data"]["title"] == "History note"
    end
  end
end
