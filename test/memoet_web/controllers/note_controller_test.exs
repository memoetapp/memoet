defmodule MemoetWeb.NoteControllerTest do
  use MemoetWeb.ConnCase

  alias Memoet.Repo

  import Memoet.Factory
  import Memoet.TestUtils

  describe "GET /notes/new" do
    setup [:create_user, :log_in, :create_deck]

    test "shows create new note form", %{conn: conn, deck: deck} do
      conn = get(conn, "/decks/" <> deck.id <> "/notes/new")
      assert html_response(conn, 200) =~ "Create new note"
    end
  end

  describe "GET /notes" do
    setup [:create_user, :log_in, :create_deck]

    test "shows empty screen if no notes", %{conn: conn, deck: deck} do
      conn = get(conn, "/decks/" <> deck.id)
      assert html_response(conn, 200) =~ "No notes is created for this deck yet"
    end

    test "lists all your notes", %{conn: conn, deck: deck} do
      insert(:note, deck: deck, title: "Geography note")
      conn = get(conn, "/decks/" <> deck.id)

      assert html_response(conn, 200) =~ "Geography note"
    end
  end

  describe "POST /notes" do
    setup [:create_user, :log_in, :create_deck]

    test "create new note", %{conn: conn, deck: deck} do
      link_notes = "/decks/" <> deck.id <> "/notes"
      conn =
        post(conn, link_notes, %{
          "note" => %{
            "title" => "History note",
            "content" => ""
          }
        })

      assert String.starts_with?(redirected_to(conn), link_notes)
      assert Repo.exists?(Memoet.Notes.Note, name: "History note")
    end
  end
end
