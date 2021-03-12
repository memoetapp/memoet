defmodule MemoetWeb.NoteController do
  use MemoetWeb, :controller

  alias Memoet.Notes
  alias Memoet.Notes.Note
  alias Memoet.Utils.StringUtil
  alias Memoet.Decks

  @spec index(Plug.Conn.t(), map) :: Plug.Conn.t()
  def index(conn, %{"deck_id" => deck_id} = _params) do
    user = Pow.Plug.current_user(conn)
    deck = Decks.get_deck!(deck_id, user.id)
    notes = Notes.list_notes(deck.id, %{})
    render(conn, "index.html", notes: notes)
  end

  @spec create(Plug.Conn.t(), map) :: Plug.Conn.t()
  def create(conn, %{"deck_id" => deck_id} = note_params) do
    user = Pow.Plug.current_user(conn)
    params =
      note_params
      |> Map.merge(%{
        "user_id" => user.id
      })

    case Notes.create_note(params) do
      {:ok, %Note{} = note} ->
        conn
        |> put_flash(:info, "Create note \"" <> note.title <> "\" success!")
        |> redirect(to: "/decks/" <> deck_id <> "/notes/" <> note.id)

      {:error, changeset} ->
        conn
        |> put_flash(:error, StringUtil.changeset_error_to_string(changeset))
        |> redirect(to: "/decks/" <> deck_id <> "/notes")
    end
  end

  @spec show(Plug.Conn.t(), map) :: Plug.Conn.t()
  def show(conn, %{"id" => id}) do
    user = Pow.Plug.current_user(conn)
    note = Notes.get_note!(id, user.id)
    render(conn, "show.html", note: note)
  end

  @spec new(Plug.Conn.t(), map) :: Plug.Conn.t()
  def new(conn, %{"deck_id" => deck_id} = _params) do
    user = Pow.Plug.current_user(conn)
    deck = Decks.get_deck!(deck_id, user.id)
    render(conn, "new.html", deck: deck)
  end

  @spec edit(Plug.Conn.t(), map) :: Plug.Conn.t()
  def edit(conn, %{"id" => id}) do
    user = Pow.Plug.current_user(conn)
    note = Notes.get_note!(id, user.id)
    render(conn, "edit.html", note: note)
  end

  @spec update(Plug.Conn.t(), map) :: Plug.Conn.t()
  def update(conn, %{"deck_id" => deck_id, "id" => id} = note_params) do
    user = Pow.Plug.current_user(conn)
    note = Notes.get_note!(id, user.id)

    case Notes.update_note(note, note_params) do
      {:ok, %Note{} = note} ->
        conn
        |> put_flash(:info, "Update note success!")
        |> redirect(to: "/decks/" <> deck_id <> "/notes/" <> note.id)

      {:error, changeset} ->
        conn
        |> put_flash(:error, StringUtil.changeset_error_to_string(changeset))
        |> redirect(to: "/decks/" <> deck_id <> "/notes/" <> note.id)
    end
  end
end
