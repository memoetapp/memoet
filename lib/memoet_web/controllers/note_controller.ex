defmodule MemoetWeb.NoteController do
  use MemoetWeb, :controller

  alias Memoet.Notes
  alias Memoet.Notes.{Note, Option}
  alias Memoet.Decks

  plug :put_layout, "deck.html"

  @spec create(Plug.Conn.t(), map) :: Plug.Conn.t()
  def create(conn, %{"deck_id" => deck_id, "note" => note_params} = _params) do
    user = Pow.Plug.current_user(conn)
    params =
      note_params
      |> Map.merge(%{
        "deck_id" => deck_id,
        "user_id" => user.id
      })

    case Notes.create_note(params) do
      {:ok, %Note{} = note} ->
        conn
        |> put_flash(:info, "Create note \"" <> note.title <> "\" success!")
        |> redirect(to: "/decks/" <> deck_id <> "/notes/" <> note.id)

      {:error, changeset} ->
        deck = Decks.get_deck!(deck_id, user.id)
        conn
        |> render("new.html", changeset: changeset, deck: deck)
    end
  end

  @spec show(Plug.Conn.t(), map) :: Plug.Conn.t()
  def show(conn, %{"id" => id, "deck_id" => deck_id}) do
    user = Pow.Plug.current_user(conn)
    note = Notes.get_note!(id, user.id)
    deck = Decks.get_deck!(deck_id)
    render(conn, "show.html", note: note, deck: deck)
  end

  @spec new(Plug.Conn.t(), map) :: Plug.Conn.t()
  def new(conn, %{"deck_id" => deck_id} = _params) do
    user = Pow.Plug.current_user(conn)
    deck = Decks.get_deck!(deck_id, user.id)

    embedded_changeset = [
      Option.changeset(%Option{}, %{"content" => "Remember", "correct" => true}),
      Option.changeset(%Option{}, %{"content" => "Forget", "correct" => false}),
      Option.changeset(%Option{}, %{}),
      Option.changeset(%Option{}, %{}),
    ]
    changeset = Note.changeset(%Note{options: embedded_changeset}, %{})

    render(conn, "new.html", deck: deck, changeset: changeset)
  end

  @spec edit(Plug.Conn.t(), map) :: Plug.Conn.t()
  def edit(conn, %{"deck_id" => deck_id, "id" => id}) do
    user = Pow.Plug.current_user(conn)
    note = Notes.get_note!(id, user.id)
    deck = Decks.get_deck!(deck_id, user.id)

    changeset = Note.changeset(note, %{})

    render(conn, "edit.html", note: note, deck: deck, changeset: changeset)
  end

  @spec update(Plug.Conn.t(), map) :: Plug.Conn.t()
  def update(conn, %{"deck_id" => deck_id, "id" => id, "note" => note_params} = _params) do
    user = Pow.Plug.current_user(conn)
    note = Notes.get_note!(id, user.id)

    case Notes.update_note(note, note_params) do
      {:ok, %Note{} = note} ->
        conn
        |> put_flash(:info, "Update note success!")
        |> redirect(to: "/decks/" <> deck_id <> "/notes/" <> note.id)

      {:error, changeset} ->
        deck = Decks.get_deck!(deck_id, user.id)
        conn
        |> render("edit.html", changeset: changeset, deck: deck)
    end
  end
end
