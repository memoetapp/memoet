defmodule MemoetWeb.NoteControllerTest do
  use MemoetWeb.ConnCase

  alias Memoet.Repo

  import Memoet.Factory
  import Memoet.TestUtils
  import Phoenix.LiveViewTest

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

  describe "LV /decks/:deck_id/import" do
    setup [:create_user, :log_in, :create_deck]

    test "import notes page", %{conn: conn, deck: deck} do
      conn = get(conn, Routes.deck_path(conn, :import, deck.id))
      assert html_response(conn, 200) =~ ~r{Import notes\s*</h1>}

      {:ok, _view, html} = live(conn)
      assert html =~ ~r{Import notes\s*</h1>}
    end
  end

  describe "LV /decks/:deck_id/import CSV upload" do
    setup [:create_user, :log_in, :create_deck]

    test "upload CSV file", %{conn: conn, deck: deck} do
      conn = get(conn, Routes.deck_path(conn, :import, deck.id))
      {:ok, lv, _html} = live(conn)

      import_file = "assets/static/files/memoet_import_template.csv"

      csv =
        file_input(lv, "#import-form", :csv, [
          %{
            last_modified: 1_594_171_879_000,
            name: "import.csv",
            content: File.read!(import_file),
            size: File.stat!(import_file).size,
            type: "text/csv"
          }
        ])

      assert render_upload(csv, "import.csv") =~ "100%"

      lv
      |> element("#import-form")
      |> render_submit(%{csv: csv})

      %{metadata: metadata} = Memoet.Notes.list_notes(%{"deck_id" => deck.id})
      assert metadata.total_count == 3
      assert render(lv) =~ "Imported 3 notes successfully!"
    end
  end
end
