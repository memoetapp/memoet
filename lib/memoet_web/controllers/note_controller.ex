defmodule MemoetWeb.NoteController do
  use MemoetWeb, :controller

  alias Memoet.Notes
  alias Memoet.Notes.{Note, Option}
  alias Memoet.Decks

  @options_limit 5

  @spec create(Plug.Conn.t(), map) :: Plug.Conn.t()
  def create(conn, %{"deck_id" => deck_id, "note" => note_params} = _params) do
    user = Pow.Plug.current_user(conn)

    params =
      note_params
      |> Map.merge(%{
        "deck_id" => deck_id,
        "user_id" => user.id
      })

    Notes.create_note_with_card_transaction(params)
    |> Memoet.Repo.transaction()
    |> case do
      {:ok, %{note: note}} ->
        conn
        |> put_flash(:info, "Create note success!")
        |> redirect(to: "/decks/" <> deck_id <> "/notes/" <> note.id)

      {:error, _op, changeset, _changes} ->
        deck = Decks.get_deck!(deck_id, user.id)

        conn
        |> render("new.html", changeset: changeset, deck: deck)
    end
  end

  @spec show(Plug.Conn.t(), map) :: Plug.Conn.t()
  def show(conn, %{"id" => id, "deck_id" => deck_id}) do
    user = Pow.Plug.current_user(conn)
    deck = Decks.get_deck!(deck_id)
    note = Notes.get_note!(id)

    if note.user_id != user.id and not deck.public do
      redirect(conn, to: "/decks")
    else
      render(conn, "show.html", note: note, deck: deck)
    end
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
      Option.changeset(%Option{}, %{})
    ]

    changeset = Note.changeset(%Note{options: embedded_changeset}, %{})

    render(conn, "new.html", deck: deck, changeset: changeset)
  end

  @spec delete(Plug.Conn.t(), map) :: Plug.Conn.t()
  def delete(conn, %{"deck_id" => deck_id, "id" => id}) do
    user = Pow.Plug.current_user(conn)
    Notes.delete_note!(id, user.id)

    conn
    |> put_flash(:info, "Delete success!")
    |> redirect(to: "/decks/" <> deck_id)
  end

  @spec edit(Plug.Conn.t(), map) :: Plug.Conn.t()
  def edit(conn, %{"deck_id" => deck_id, "id" => id}) do
    user = Pow.Plug.current_user(conn)
    note = Notes.get_note!(id, user.id)
    deck = Decks.get_deck!(deck_id, user.id)

    empty_options = @options_limit - length(note.options)

    options =
      if empty_options > 0 do
        note.options ++ for _ <- 1..empty_options, do: Option.changeset(%Option{}, %{})
      else
        note.options
      end

    changeset = Note.changeset(%Note{note | options: options}, %{})
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
