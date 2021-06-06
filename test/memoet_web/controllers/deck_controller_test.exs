defmodule MemoetWeb.DeckControllerTest do
  use MemoetWeb.ConnCase

  alias Memoet.Repo
  alias Memoet.Decks.Deck

  import Memoet.Factory
  import Memoet.TestUtils
  import Phoenix.LiveViewTest

  describe "GET /decks/new" do
    setup [:create_user, :log_in]

    test "shows create new deck form", %{conn: conn} do
      conn = get(conn, "/decks/new")
      assert html_response(conn, 200) =~ "Create a new deck"
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

  describe "GET /community" do
    setup [:create_user, :log_in, :create_deck]

    test "lists none", %{conn: conn} do
      conn = get(conn, "/community")

      assert html_response(conn, 200) =~ "No decks is listed here"
    end

    test "public deck is accessable", %{conn: conn, deck: deck} do
      deck
      |> Deck.changeset(%{public: true})
      |> Repo.update()

      conn = get(conn, "/community/" <> deck.id)
      assert html_response(conn, 200) =~ deck.name

      conn = get(conn, "/community")
      assert html_response(conn, 200) =~ "No decks is listed here"
    end

    test "public & listed deck is accessable and listed", %{conn: conn, deck: deck} do
      deck
      |> Deck.changeset(%{public: true, listed: true})
      |> Repo.update()

      conn = get(conn, "/community/" <> deck.id)
      assert html_response(conn, 200) =~ deck.name

      conn = get(conn, "/community")
      assert html_response(conn, 200) =~ deck.name
    end
  end

  describe "GET /decks/:deck_id/practice" do
    setup [:create_user, :log_in, :create_deck]

    test "list no more notes", %{conn: conn, deck: deck} do
      conn = get(conn, "/decks/" <> deck.id <> "/practice")

      assert html_response(conn, 200) =~ "No more notes"
    end

    test "list & practice a new note", %{conn: conn, deck: deck} do
      deck_practice = "/decks/" <> deck.id <> "/practice"
      deck_notes = "/decks/" <> deck.id <> "/notes"

      # List a note
      post(conn, deck_notes, %{
        "note" => %{
          "title" => "A new note",
        }
      })

      first_conn = get(conn, deck_practice)
      assert html_response(first_conn, 200) =~ "A new note"
      assert html_response(first_conn, 200) =~ "10m"

      # Answer it first time, change from 10m -> 1d
      card_id = List.last(Regex.run(~r/name="card_id" value="(.+)">/, html_response(first_conn, 200)))
      note_id = List.last(Regex.run(~r/notes\/(.+)\/edit/, html_response(first_conn, 200)))

      second_conn = put(conn, deck_practice, %{
        "id" => deck.id,
        "card_id" => card_id,
        "answer" => 3,
        "visit_time" => 1234
      })
      assert redirected_to(second_conn, 302) =~ deck_practice

      third_conn = get(conn, deck_practice)
      assert html_response(third_conn, 200) =~ "1d"

      # Answer it second time, from 1d -> 3d
      fourth_conn = put(conn, deck_practice, %{
        "id" => deck.id,
        "card_id" => card_id,
        "answer" => 3,
        "visit_time" => 1234
      })
      assert redirected_to(fourth_conn, 302) =~ deck_practice

      fifth_conn = get(conn, deck_practice <> "?note_id=" <> note_id)
      assert html_response(fifth_conn, 200) =~ "3d"

      # Answer it third time, still 3d
      sixth_conn = put(conn, deck_practice, %{
        "id" => deck.id,
        "card_id" => card_id,
        "answer" => 3,
        "visit_time" => 1234
      })
      assert redirected_to(sixth_conn, 302) =~ deck_practice

      seventh_conn = get(conn, deck_practice <> "?note_id=" <> note_id)
      assert html_response(seventh_conn, 200) =~ "3d"
    end
  end
end
