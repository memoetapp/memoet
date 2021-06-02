defmodule MemoetWeb.DeckControllerTest do
  use MemoetWeb.ConnCase

  alias Memoet.Repo

  import Memoet.Factory
  import Memoet.TestUtils
  import Phoenix.LiveViewTest

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
